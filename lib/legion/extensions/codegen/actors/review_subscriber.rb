# frozen_string_literal: true

module Legion
  module Extensions
    module Codegen
      module Actor
        module ReviewSubscriber
          QUEUE = Transport::Queues::ReviewCompleted if defined?(Transport::Queues::ReviewCompleted)

          def action(payload)
            review = {
              generation_id: payload[:generation_id],
              verdict:       payload[:verdict]&.to_sym,
              confidence:    payload[:confidence],
              issues:        payload[:issues] || [],
              scores:        payload[:scores] || {}
            }

            Runners::ReviewHandler.handle_verdict(review: review)
          rescue StandardError => e
            log&.warn("ReviewSubscriber failed: #{e.message}")
            { success: false, error: e.message }
          end

          private

          def log
            return unless defined?(Legion::Logging)

            Legion::Logging
          end
        end
      end
    end
  end
end
