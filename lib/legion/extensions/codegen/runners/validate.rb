# frozen_string_literal: true

require 'yaml'

module Legion
  module Extensions
    module Codegen
      module Runners
        module Validate
          extend self

          REQUIRED_FILES = %w[
            Gemfile
            .rubocop.yml
            spec/spec_helper.rb
          ].freeze

          REQUIRED_RUBOCOP_KEYS = %w[
            AllCops
            Layout/LineLength
            Metrics/MethodLength
            Style/FrozenStringLiteralComment
          ].freeze

          REQUIRED_GEMSPEC_FIELDS = %w[name version authors email summary description homepage license].freeze

          def validate_structure(path:, **)
            raise ArgumentError, 'Path must be a string' unless path.is_a?(String)

            present = []
            missing = []

            REQUIRED_FILES.each do |rel|
              full = ::File.join(path, rel)
              if ::File.exist?(full)
                present << rel
              else
                missing << rel
              end
            end

            gemspec = ::Dir.glob(::File.join(path, '*.gemspec')).first
            if gemspec
              present << '*.gemspec'
            else
              missing << '*.gemspec'
            end

            entry = entry_point_path(path)
            if entry && ::File.exist?(entry)
              present << 'lib/legion/extensions/<name>.rb'
            else
              missing << 'lib/legion/extensions/<name>.rb'
            end

            version = version_path(path)
            if version && ::File.exist?(version)
              present << 'lib/legion/extensions/<name>/version.rb'
            else
              missing << 'lib/legion/extensions/<name>/version.rb'
            end

            { valid: missing.empty?, missing: missing, present: present }
          rescue ArgumentError => e
            { valid: false, missing: [], present: [], error: e.message }
          end

          def validate_rubocop_config(path:, **)
            rubocop_path = ::File.join(path, '.rubocop.yml')
            return { valid: false, issues: ['.rubocop.yml not found'] } unless ::File.exist?(rubocop_path)

            config = YAML.safe_load_file(rubocop_path) || {}
            issues = []

            REQUIRED_RUBOCOP_KEYS.each do |key|
              issues << "Missing key: #{key}" unless config.key?(key)
            end

            target = config.dig('AllCops', 'TargetRubyVersion')&.to_s
            unless target == Helpers::Constants::DEFAULT_RUBY_VERSION
              issues << "AllCops/TargetRubyVersion should be #{Helpers::Constants::DEFAULT_RUBY_VERSION}"
            end

            { valid: issues.empty?, issues: issues }
          rescue ArgumentError => e
            { valid: false, issues: [e.message] }
          end

          def validate_gemspec(path:, **)
            gemspec_path = ::Dir.glob(::File.join(path, '*.gemspec')).first
            return { valid: false, issues: ['No .gemspec file found'] } unless gemspec_path

            content = ::File.read(gemspec_path)
            issues  = []

            REQUIRED_GEMSPEC_FIELDS.each do |field|
              issues << "Missing gemspec field: #{field}" unless content.include?(field)
            end

            issues << 'Missing rubygems_mfa_required metadata' unless content.include?('rubygems_mfa_required')
            issues << 'Missing required_ruby_version' unless content.include?('required_ruby_version')

            { valid: issues.empty?, issues: issues, path: gemspec_path }
          rescue ArgumentError => e
            { valid: false, issues: [e.message] }
          end

          private

          def entry_point_path(path)
            candidates = ::Dir.glob(::File.join(path, 'lib/legion/extensions/*.rb'))
            candidates.reject { |f| f.include?('/extensions/') && f.split('/').last.include?('/') }.first
          end

          def version_path(path)
            candidates = ::Dir.glob(::File.join(path, 'lib/legion/extensions/*/version.rb'))
            candidates.first
          end
        end
      end
    end
  end
end
