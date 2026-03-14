# frozen_string_literal: true

module Legion
  module Extensions
    module Codegen
      module Runners
        module Template
          extend self # rubocop:disable Style/ModuleFunction

          TEMPLATE_REQUIRED_VARS = {
            gemspec:     %i[gem_name module_name description author email ruby_version license extra_deps],
            gemfile:     [],
            rubocop:     %i[ruby_version],
            ci:          [],
            rspec:       [],
            gitignore:   [],
            license:     %i[author],
            version:     %i[module_name gem_version],
            entry_point: %i[gem_name_underscored module_name helpers runner_names],
            spec_helper: %i[gem_name_underscored],
            runner:      %i[module_name runner_class methods gem_name_underscored],
            client:      %i[module_name runner_names]
          }.freeze

          def list_templates(**)
            { success: true, templates: Helpers::Constants::TEMPLATE_TYPES }
          end

          def render_template(template_type:, variables: {}, **)
            engine  = Helpers::TemplateEngine.new
            content = engine.render(template_type, variables)
            { success: true, content: content, template_type: template_type }
          rescue ArgumentError => e
            { success: false, error: e.message }
          end

          def template_variables(template_type:, **)
            key = template_type.to_sym
            return { success: false, error: "Unknown template type: #{template_type}" } unless Helpers::Constants::TEMPLATE_TYPES.include?(key)

            required = TEMPLATE_REQUIRED_VARS.fetch(key, [])
            { success: true, template_type: key, required_variables: required }
          end
        end
      end
    end
  end
end
