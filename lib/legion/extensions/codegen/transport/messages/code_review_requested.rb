# frozen_string_literal: true

module Legion
  module Extensions
    module Codegen
      module Transport
        module Messages
          class CodeReviewRequested < Legion::Transport::Message
            def initialize(generation:, **)
              @generation = generation
              super(**)
            end

            def message
              {
                generation_id: @generation[:generation_id],
                gap:           { id: @generation[:gap_id], type: @generation[:gap_type] },
                runner_code:   @generation[:code],
                spec_code:     @generation[:spec_code],
                tier:          @generation[:tier],
                attempt:       @generation[:attempt_count] || 0
              }
            end

            def routing_key
              'eval.code_review.requested'
            end
          end
        end
      end
    end
  end
end
