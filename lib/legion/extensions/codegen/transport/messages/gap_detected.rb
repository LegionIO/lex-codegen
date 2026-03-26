# frozen_string_literal: true

module Legion
  module Extensions
    module Codegen
      module Transport
        module Messages
          class GapDetected < Legion::Transport::Message
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
