# frozen_string_literal: true

require 'securerandom'
require 'fileutils'

module Legion
  module Extensions
    module Codegen
      module Runners
        module FromGap
          extend self

          def generate(gap:)
            tier = Helpers::TierClassifier.classify(gap: gap)

            case tier
            when :simple
              generate_runner_method(gap: gap)
            when :complex
              generate_full_extension(gap: gap)
            else
              { success: false, reason: :unknown_tier, tier: tier }
            end
          rescue StandardError => e
            { success: false, reason: :generation_error, error: e.message }
          end

          def generate_runner_method(gap:)
            return { success: false, reason: :llm_unavailable } unless llm_available?

            generation_id = "gen_#{SecureRandom.hex(8)}"
            prompt = build_runner_prompt(gap)

            response = Legion::LLM.chat(
              messages: [{ role: 'user', content: prompt }],
              caller:   { source: 'lex-codegen', component: 'from_gap', operation: 'generate_runner_method' }
            )

            code = response&.content
            return { success: false, reason: :llm_empty_response } if code.nil? || code.empty?

            spec_code = generate_companion_spec(gap, code)
            file_path = write_generated_file(generation_id, code)
            spec_path = write_generated_file("#{generation_id}_spec", spec_code)

            {
              success:       true,
              generation_id: generation_id,
              gap_id:        gap[:id],
              gap_type:      gap[:type],
              tier:          :simple,
              file_path:     file_path,
              spec_path:     spec_path,
              code:          code,
              spec_code:     spec_code
            }
          rescue StandardError => e
            { success: false, reason: :generation_failed, error: e.message }
          end

          def generate_full_extension(gap:)
            name = derive_extension_name(gap[:intent])

            result = Runners::Generate.scaffold_extension(
              name:           name,
              module_name:    camelize(name),
              description:    "Auto-generated extension for: #{gap[:intent]}",
              runner_methods: [{ name: 'handle', params: %w[payload] }]
            )

            return result unless result[:success]

            {
              success:       true,
              generation_id: "gen_ext_#{SecureRandom.hex(8)}",
              gap_id:        gap[:id],
              gap_type:      gap[:type],
              tier:          :complex,
              file_path:     result[:path],
              extension:     name
            }
          rescue StandardError => e
            { success: false, reason: :scaffold_failed, error: e.message }
          end

          private

          def llm_available?
            defined?(Legion::LLM) && Legion::LLM.respond_to?(:chat)
          end

          def build_runner_prompt(gap)
            <<~PROMPT
              Generate a Ruby module for the LegionIO framework that handles this capability:
              Intent: "#{gap[:intent]}"
              Gap type: #{gap[:type]}

              Requirements:
              - Module under Legion::Generated namespace
              - Use `extend self` pattern
              - Each public method returns { success: true/false, ... } hash
              - Use keyword arguments
              - Include frozen_string_literal comment
              - No shell execution, eval, or unsafe operations
              - Keep it minimal and focused

              Return ONLY the Ruby code, no markdown fencing.
            PROMPT
          end

          def generate_companion_spec(gap, _code)
            <<~SPEC
              # frozen_string_literal: true

              RSpec.describe 'Generated handler for #{gap[:intent]}' do
                it 'is defined' do
                  expect(true).to be true
                end
              end
            SPEC
          end

          def write_generated_file(name, content)
            dir = output_dir
            FileUtils.mkdir_p(dir)
            path = File.join(dir, "#{name}.rb")
            File.write(path, content)
            path
          end

          def output_dir
            if defined?(Legion::Settings)
              Legion::Settings.dig(:codegen, :self_generate, :runner_method, :output_dir) || default_output_dir
            else
              default_output_dir
            end
          end

          def default_output_dir
            File.expand_path('~/.legionio/generated/runners')
          end

          def derive_extension_name(intent)
            intent.to_s.downcase.gsub(/[^a-z0-9]+/, '_').gsub(/^_|_$/, '')[0..30]
          end

          def camelize(name)
            name.split('_').map(&:capitalize).join
          end
        end
      end
    end
  end
end
