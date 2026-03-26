# frozen_string_literal: true

module Legion
  module Extensions
    module Codegen
      module Transport
        module Queues
          class ReviewCompleted < Legion::Transport::Queue
            def queue_name
              'codegen.review_completed'
            end

            def queue_options
              { durable: true }
            end

            def routing_key
              'codegen.review.completed'
            end

            def exchange
              Exchanges::Codegen
            end
          end
        end
      end
    end
  end
end
