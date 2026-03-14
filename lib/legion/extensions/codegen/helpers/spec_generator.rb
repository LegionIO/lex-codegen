# frozen_string_literal: true

module Legion
  module Extensions
    module Codegen
      module Helpers
        class SpecGenerator
          def initialize
            # no state needed
          end

          def generate_runner_spec(module_name:, runner_name:, methods: [])
            runner_class = runner_name.split('_').map(&:capitalize).join
            lines = [
              '# frozen_string_literal: true',
              '',
              "RSpec.describe Legion::Extensions::#{module_name}::Runners::#{runner_class} do",
              '  subject(:runner) { described_class }',
              ''
            ]

            methods.each do |m|
              method_name = m[:name]
              lines << "  describe '.#{method_name}' do"
              lines << "    it 'responds to #{method_name}' do"
              lines << "      expect(runner).to respond_to(:#{method_name})"
              lines << '    end'
              lines << ''
              lines << "    it 'returns a hash with success key' do"

              call_args = build_call_args(m[:params])
              lines << "      result = runner.#{method_name}(#{call_args})"
              lines << '      expect(result).to be_a(Hash)'
              lines << '      expect(result).to have_key(:success)'
              lines << '    end'
              lines << '  end'
              lines << ''
            end

            lines << 'end'
            "#{lines.join("\n")}\n"
          end

          def generate_client_spec(module_name:, runner_name: nil, methods: []) # rubocop:disable Lint/UnusedMethodArgument
            lines = [
              '# frozen_string_literal: true',
              '',
              "RSpec.describe Legion::Extensions::#{module_name}::Client do",
              '  subject(:client) { described_class.new }',
              ''
            ]

            lines << "  it 'instantiates successfully' do"
            lines << '    expect(client).to be_a(described_class)'
            lines << '  end'
            lines << ''

            methods.each do |m|
              lines << "  it 'responds to #{m[:name]}' do"
              lines << "    expect(client).to respond_to(:#{m[:name]})"
              lines << '  end'
              lines << ''
            end

            lines << 'end'
            "#{lines.join("\n")}\n"
          end

          def generate_helper_spec(module_name:, helper_name:, methods: [])
            helper_class = helper_name.split('_').map(&:capitalize).join
            lines = [
              '# frozen_string_literal: true',
              '',
              "RSpec.describe Legion::Extensions::#{module_name}::Helpers::#{helper_class} do",
              '  subject(:helper) { described_class.new }',
              ''
            ]

            lines << "  it 'instantiates successfully' do"
            lines << '    expect(helper).to be_a(described_class)'
            lines << '  end'
            lines << ''

            methods.each do |m|
              lines << "  it 'responds to #{m[:name]}' do"
              lines << "    expect(helper).to respond_to(:#{m[:name]})"
              lines << '  end'
              lines << ''
            end

            lines << 'end'
            "#{lines.join("\n")}\n"
          end

          private

          def build_call_args(params)
            return '' if params.nil? || params.empty?

            keyword_params = params.reject { |p| ['**', '*args'].include?(p) }
            return '' if keyword_params.empty?

            keyword_params.map do |p|
              name = p.to_s.gsub(/[:\s].*/, '').chomp(':')
              "#{name}: nil"
            end.join(', ')
          end
        end
      end
    end
  end
end
