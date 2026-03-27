# frozen_string_literal: true

return unless defined?(Legion::Extensions::Actors::Subscription)

module Legion
  module Extensions
    module Codegen
      module Actor
        class ReviewSubscriber < Legion::Extensions::Actors::Subscription
          QUEUE = Transport::Queues::ReviewCompleted if defined?(Transport::Queues::ReviewCompleted)

          def runner_class = self.class
          def runner_function = 'action'

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
