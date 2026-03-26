# frozen_string_literal: true

module Legion
  module Extensions
    module Codegen
      module Actor
        module GapSubscriber
          QUEUE = Transport::Queues::GapDetected if defined?(Transport::Queues::GapDetected)

          def action(payload)
            gap = normalize_gap(payload)
            result = Runners::FromGap.generate(gap: gap)

            Transport::Messages::CodeReviewRequested.new(generation: result).publish if result[:success] && defined?(Transport::Messages::CodeReviewRequested)

            result
          rescue StandardError => e
            Legion::Logging.warn("GapSubscriber failed: #{e.message}") if defined?(Legion::Logging)
            { success: false, error: e.message }
          end

          private

          def normalize_gap(payload)
            {
              id:               payload[:gap_id] || payload[:id],
              type:             (payload[:gap_type] || payload[:type])&.to_sym,
              intent:           payload[:intent],
              occurrence_count: payload[:occurrence_count] || 1,
              priority:         payload[:priority] || 0.5,
              metadata:         payload[:metadata] || {}
            }
          end
        end
      end
    end
  end
end
