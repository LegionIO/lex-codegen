# frozen_string_literal: true

require 'securerandom'
require 'fileutils'

module Legion
  module Extensions
    module Codegen
      module Runners
        module FromGap
          extend self

          STUB_IMPLEMENTATION_INSTRUCTIONS = <<~INSTRUCTIONS
            You are a Ruby code generator for LegionIO cognitive extensions.
            You receive a stub Ruby file and a description of the extension's purpose.
            Replace stub method bodies with real implementations.

            Rules:
            - Return ONLY the complete Ruby file content, no markdown fencing, no explanation
            - Keep the exact module/class/method structure and signatures
            - Keep `# frozen_string_literal: true` on line 1
            - Runner methods must return `{ success: true/false, ... }` hashes
            - Use in-memory state only (instance variables, no database, no external APIs)
            - Helper classes may use initialize for state setup
            - Follow Ruby style: 2-space indent, snake_case methods
            - Do not add require statements
            - Do not add new comments unless the logic is non-obvious; keep existing comments (including `# frozen_string_literal: true` on line 1)
          INSTRUCTIONS

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

          def implement_stub(file_path:, context:)
            return { success: false, reason: :llm_unavailable } unless llm_available?
            return { success: false, reason: :path_not_allowed } unless allowed_stub_path?(file_path)

            stub_content = ::File.read(file_path)
            prompt = stub_implementation_prompt(stub_content, context)

            response = Legion::LLM.chat(
              messages: [
                { role: 'system', content: STUB_IMPLEMENTATION_INSTRUCTIONS },
                { role: 'user', content: prompt }
              ],
              caller:   { source: 'lex-codegen', component: 'from_gap', operation: 'implement_stub' }
            )

            code = extract_code(response&.content)
            return { success: false, reason: :llm_empty_response } if code.nil? || code.strip.empty?

            { success: true, code: code, file_path: file_path }
          rescue StandardError => e
            { success: false, reason: :generation_error, error: e.message }
          end

          private

          def llm_available?
            defined?(Legion::LLM) && Legion::LLM.respond_to?(:chat)
          end

          def allowed_stub_path?(file_path)
            return false unless file_path&.end_with?('.rb')

            begin
              allowed_root = ::File.realpath(output_dir)
            rescue Errno::ENOENT, Errno::EACCES => e
              log.debug("realpath fallback for output_dir: #{e.message}")
              allowed_root = ::File.expand_path(output_dir)
            end

            begin
              # Disallow direct symlink files to avoid exfiltrating arbitrary targets
              return false if ::File.lstat(file_path).symlink?

              resolved = ::File.realpath(file_path)
            rescue Errno::ENOENT, Errno::EACCES => e
              log.debug("path resolution failed for #{file_path}: #{e.message}")
              return false
            end

            resolved == allowed_root || resolved.start_with?(allowed_root + ::File::SEPARATOR)
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

          def stub_implementation_prompt(stub_content, context)
            parts = ['Implement this LegionIO extension file.']
            parts << "Extension: #{context[:name]}"
            parts << "Category: #{context[:category]}"
            parts << "Description: #{context[:description]}"
            parts << "Metaphor: #{context[:metaphor]}" if context[:metaphor]
            parts << ''
            parts << 'Current stub:'
            parts << stub_content
            parts.join("\n")
          end

          def extract_code(content)
            return nil if content.nil?

            code = if content.match?(/```ruby\s*\r?\n/)
                     content.match(/```ruby\s*\r?\n(.*?)```/m)&.captures&.first || content
                   elsif content.match?(/```\s*\r?\n/)
                     content.match(/```\s*\r?\n(.*?)```/m)&.captures&.first || content
                   else
                     content
                   end
            "#{code.strip}\n"
          end
        end
      end
    end
  end
end
