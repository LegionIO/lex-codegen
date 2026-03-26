# frozen_string_literal: true

module Legion
  module Extensions
    module Codegen
      module Helpers
        module TierClassifier
          DEFAULT_SIMPLE_MAX = 10

          module_function

          def classify(gap:)
            count = gap[:occurrence_count] || 0
            threshold = simple_max_occurrences

            count <= threshold ? :simple : :complex
          end

          def simple_max_occurrences
            if defined?(Legion::Settings)
              Legion::Settings.dig(:codegen, :self_generate, :tier, :simple_max_occurrences) || DEFAULT_SIMPLE_MAX
            else
              DEFAULT_SIMPLE_MAX
            end
          end
        end
      end
    end
  end
end
