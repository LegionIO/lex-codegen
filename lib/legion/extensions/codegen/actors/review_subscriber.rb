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
          def check_subtask? = true

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
            log.warn("ReviewSubscriber failed: #{e.message}")
            { success: false, error: e.message }
          end

          private

          def log
            return Legion::Logging if defined?(Legion::Logging)

            @log ||= Object.new.tap do |nl|
              %i[debug info warn error fatal].each { |m| nl.define_singleton_method(m) { |*| nil } }
            end
          end
        end
      end
    end
  end
end
