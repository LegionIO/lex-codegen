# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Codegen
      module Runners
        module AutoFix
          extend self

          def auto_fix(gem_name:, runner_class:, error_class:, backtraces:, **)
            return { success: false, reason: :llm_unavailable } unless defined?(Legion::LLM)

            spec = begin
              Gem::Specification.find_by_name(gem_name)
            rescue LoadError
              nil
            end
            return { success: false, reason: :gem_not_found } unless spec

            source_file = locate_source(spec, runner_class)
            return { success: false, reason: :source_not_found } unless source_file && ::File.exist?(source_file)

            source = ::File.read(source_file)
            prompt = build_fix_prompt(source, error_class, backtraces)
            fix_response = Legion::LLM.chat(
              messages: [{ role: 'user', content: prompt }],
              caller:   { extension: 'lex-codegen', operation: 'auto_fix' },
              intent:   { capability: :reasoning }
            )

            patch = extract_patch(fix_response)
            return { success: false, reason: :no_patch_generated } unless patch

            branch = "fix/#{gem_name}-#{::Time.now.to_i}"
            apply_result = apply_and_test(spec.gem_dir, branch, source_file, patch)

            fix_id = save_fix(gem_name: gem_name, runner_class: runner_class,
                              branch: branch, patch: patch,
                              specs_passed: apply_result[:specs_passed],
                              spec_output: apply_result[:output])

            { success: apply_result[:specs_passed], fix_id: fix_id, branch: branch,
              specs_passed: apply_result[:specs_passed] }
          rescue StandardError => e
            { success: false, reason: :error, message: e.message }
          end

          def approve_fix(fix_id:, **)
            update_fix_status(fix_id, 'approved')
          end

          def reject_fix(fix_id:, **)
            update_fix_status(fix_id, 'rejected')
          end

          def list_fixes(status: nil, **)
            return { fixes: [], count: 0 } unless defined?(Legion::Data::Local)

            ds = Legion::Data::Local.connection[:codegen_fixes]
            ds = ds.where(status: status) if status
            fixes = ds.order(Sequel.desc(:created_at)).limit(50).all
            { fixes: fixes, count: fixes.size }
          rescue StandardError
            { fixes: [], count: 0 }
          end

          private

          def locate_source(spec, runner_class)
            relative = runner_class.gsub('::', '/').gsub(%r{^Legion/Extensions/}, '')
                                   .downcase.gsub(/([a-z])([A-Z])/, '\1_\2').downcase
            path = ::File.join(spec.gem_dir, 'lib', "legion/extensions/#{relative}.rb")
            ::File.exist?(path) ? path : nil
          end

          def build_fix_prompt(source, error_class, backtraces)
            <<~PROMPT
              You are a Ruby debugging expert. A Legion extension runner is failing with the following error.

              **Error class**: #{error_class}

              **Backtrace**:
              #{backtraces.first(10).join("\n")}

              **Source code**:
              ```ruby
              #{source}
              ```

              Generate a minimal fix as a unified diff patch. Only change what is necessary to fix the error.
              Output ONLY the unified diff, no explanation. Start with --- and +++.
            PROMPT
          end

          def extract_patch(response)
            content = response.is_a?(Hash) ? (response[:content] || response[:text]) : response.to_s
            return nil if content.nil? || content.empty?

            lines = content.lines
            start = lines.index { |l| l.start_with?('---') }
            return nil unless start

            lines[start..].join
          end

          def apply_and_test(gem_dir, branch, source_file, patch)
            require 'open3'

            ::Dir.chdir(gem_dir) do
              Open3.capture3('git', 'checkout', '-b', branch)
              ::File.write("#{source_file}.patch", patch)
              _out, _err, status = Open3.capture3('git', 'apply', "#{source_file}.patch")
              ::FileUtils.rm_f("#{source_file}.patch")

              unless status.success?
                Open3.capture3('git', 'checkout', '-')
                Open3.capture3('git', 'branch', '-D', branch)
                return { specs_passed: false, output: 'Patch failed to apply' }
              end

              stdout, stderr, spec_status = Open3.capture3('bundle', 'exec', 'rspec', '--format', 'progress')
              output = (stdout + stderr).slice(0, 10_240)

              unless spec_status.success?
                Open3.capture3('git', 'checkout', '-')
                Open3.capture3('git', 'branch', '-D', branch)
              end

              { specs_passed: spec_status.success?, output: output }
            end
          rescue StandardError => e
            { specs_passed: false, output: e.message }
          end

          def save_fix(gem_name:, branch:, patch:, specs_passed:, runner_class: nil, spec_output: nil)
            fix_id = SecureRandom.uuid
            if defined?(Legion::Data::Local)
              Legion::Data::Local.connection[:codegen_fixes].insert(
                fix_id: fix_id, gem_name: gem_name, runner_class: runner_class,
                branch: branch, patch: patch, status: 'pending',
                specs_passed: specs_passed, spec_output: spec_output&.slice(0, 10_240)
              )
            end
            fix_id
          rescue StandardError
            fix_id
          end

          def update_fix_status(fix_id, new_status)
            return { success: false, reason: :data_unavailable } unless defined?(Legion::Data::Local)

            updated = Legion::Data::Local.connection[:codegen_fixes]
                                         .where(fix_id: fix_id)
                                         .update(status: new_status)
            if updated.positive?
              { success: true, fix_id: fix_id, status: new_status }
            else
              { success: false, reason: :not_found }
            end
          rescue StandardError => e
            { success: false, reason: :error, message: e.message }
          end
        end
      end
    end
  end
end
