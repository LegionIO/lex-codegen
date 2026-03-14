# frozen_string_literal: true

require 'erb'

module Legion
  module Extensions
    module Codegen
      module Helpers
        class TemplateEngine
          def initialize
            # no state needed
          end

          def render(template_type, variables = {})
            key = template_type.to_sym
            raise ArgumentError, "Unknown template type: #{template_type}" unless Constants::TEMPLATE_MAP.key?(key)

            render_string(Constants::TEMPLATE_MAP[key], variables)
          end

          def render_string(template_string, variables = {})
            ERB.new(template_string, trim_mode: '-').result(binding_with(variables))
          end

          private

          def binding_with(variables)
            ctx = Object.new
            variables.each do |key, value|
              ctx.instance_variable_set(:"@#{key}", value)
              ctx.define_singleton_method(key) { instance_variable_get(:"@#{key}") }
            end
            ctx.instance_eval { binding }
          end
        end
      end
    end
  end
end
