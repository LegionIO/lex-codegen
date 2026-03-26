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
            Legion::Logging.warn("ReviewSubscriber failed: #{e.message}") if defined?(Legion::Logging)
            { success: false, error: e.message }
          end
        end
      end
    end
  end
end
