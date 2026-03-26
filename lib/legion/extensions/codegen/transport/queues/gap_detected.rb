# frozen_string_literal: true

module Legion
  module Extensions
    module Codegen
      module Transport
        module Queues
          class GapDetected < Legion::Transport::Queue
            def queue_name
              'codegen.gap_detected'
            end

            def queue_options
              { durable: true }
            end

            def routing_key
              'codegen.gap.detected'
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
