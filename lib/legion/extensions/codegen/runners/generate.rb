# frozen_string_literal: true

module Legion
  module Extensions
    module Codegen
      module Runners
        module Generate
          extend self

          def scaffold_extension(name:, module_name:, description:, category: :cognition, # rubocop:disable Lint/UnusedMethodArgument
                                 helpers: [], runner_methods: [], base_path: nil, **)
            base_path ||= ::Dir.pwd
            ext_path   = ::File.join(base_path, "lex-#{name}")
            gem_name   = "lex-#{name}"
            underscored = name.to_s.gsub('-', '_')
            runner_names = runner_methods.map { |r| r[:name] }

            engine  = Helpers::TemplateEngine.new
            writer  = Helpers::FileWriter.new(base_path: ext_path)
            spec_gen = Helpers::SpecGenerator.new

            variables = build_variables(
              gem_name:     gem_name,
              underscored:  underscored,
              module_name:  module_name,
              description:  description,
              helpers:      helpers.map { |h| h.is_a?(Hash) ? h[:name] : h.to_s },
              runner_names: runner_names,
              extra_deps:   []
            )

            files = build_scaffold_files(engine, variables, helpers, runner_methods, spec_gen, module_name, underscored, runner_names)
            writer.write_all(files)

            log.info "[codegen] scaffolded #{gem_name} with #{files.size} files at #{ext_path}"
            { success: true, path: ext_path, files_created: files.size, name: gem_name }
          rescue ArgumentError => e
            { success: false, error: e.message }
          end

          def generate_file(template_type:, output_path:, variables: {}, **)
            engine = Helpers::TemplateEngine.new
            content = engine.render(template_type, variables)
            ::FileUtils.mkdir_p(::File.dirname(output_path))
            ::File.write(output_path, content)
            { success: true, path: output_path, bytes: content.bytesize }
          rescue ArgumentError => e
            { success: false, error: e.message }
          end

          private

          def log
            return Legion::Logging if defined?(Legion::Logging)

            @log ||= Object.new.tap do |nl|
              %i[debug info warn error fatal].each { |m| nl.define_singleton_method(m) { |*| nil } }
            end
          end

          def build_variables(gem_name:, underscored:, module_name:, description:, helpers:, runner_names:, extra_deps:)
            {
              gem_name:             gem_name,
              gem_name_underscored: underscored,
              module_name:          module_name,
              description:          description,
              author:               Helpers::Constants::DEFAULT_AUTHOR,
              email:                Helpers::Constants::DEFAULT_EMAIL,
              ruby_version:         Helpers::Constants::DEFAULT_RUBY_VERSION,
              gem_version:          Helpers::Constants::DEFAULT_GEM_VERSION,
              license:              Helpers::Constants::DEFAULT_LICENSE,
              helpers:              helpers,
              runner_names:         runner_names,
              extra_deps:           extra_deps
            }
          end

          def build_scaffold_files(engine, variables, helpers, runner_methods, spec_gen, module_name, underscored, runner_names)
            files = {}

            files["#{variables[:gem_name]}.gemspec"] = engine.render(:gemspec, variables)
            files['Gemfile']                                    = engine.render(:gemfile, variables)
            files['.rubocop.yml']                               = engine.render(:rubocop, variables)
            files['.github/workflows/ci.yml'] = engine.render(:ci, variables)
            files['.rspec']                                     = engine.render(:rspec, variables)
            files['.gitignore']                                 = engine.render(:gitignore, variables)
            files['LICENSE']                                    = engine.render(:license, variables)
            files["lib/legion/extensions/#{underscored}/version.rb"] = engine.render(:version, variables)
            files["lib/legion/extensions/#{underscored}.rb"] = engine.render(:entry_point, variables)
            files['spec/spec_helper.rb'] = engine.render(:spec_helper, variables)
            files["lib/legion/extensions/#{underscored}/client.rb"] = engine.render(:client, variables.merge(runner_names: runner_names))

            helpers.each do |helper|
              helper_name = helper.is_a?(Hash) ? helper[:name] : helper.to_s
              helper_methods = helper.is_a?(Hash) ? (helper[:methods] || []) : []
              files["lib/legion/extensions/#{underscored}/helpers/#{helper_name}.rb"] =
                generate_helper_stub(module_name, helper_name, helper_methods)
              files["spec/legion/extensions/#{underscored}/helpers/#{helper_name}_spec.rb"] =
                spec_gen.generate_helper_spec(module_name: module_name, helper_name: helper_name, methods: helper_methods)
            end

            runner_methods.each do |runner|
              r_name = runner[:name]
              r_methods = runner.is_a?(Hash) ? [runner] : []
              r_class = r_name.split('_').map(&:capitalize).join
              files["lib/legion/extensions/#{underscored}/runners/#{r_name}.rb"] =
                engine.render(:runner, variables.merge(runner_class: r_class, methods: [runner]))
              files["spec/legion/extensions/#{underscored}/runners/#{r_name}_spec.rb"] =
                spec_gen.generate_runner_spec(module_name: module_name, runner_name: r_name, methods: r_methods)
            end

            files["spec/legion/extensions/#{underscored}/client_spec.rb"] =
              spec_gen.generate_client_spec(module_name: module_name, runner_name: 'client', methods: [])

            files
          end

          def generate_helper_stub(module_name, helper_name, methods)
            helper_class = helper_name.split('_').map(&:capitalize).join
            method_lines = methods.map do |m|
              params = Array(m[:params])
              param_str = params.empty? ? '**' : "#{params.join(', ')}, **"
              "          def #{m[:name]}(#{param_str})\n            { success: true }\n          end"
            end.join("\n\n")

            <<~RUBY
              # frozen_string_literal: true

              module Legion
                module Extensions
                  module #{module_name}
                    module Helpers
                      class #{helper_class}
                        def initialize
                          # no state needed
                        end

              #{method_lines}
                      end
                    end
                  end
                end
              end
            RUBY
          end
        end
      end
    end
  end
end
