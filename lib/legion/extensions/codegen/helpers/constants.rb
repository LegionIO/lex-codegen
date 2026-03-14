# frozen_string_literal: true

module Legion
  module Extensions
    module Codegen
      module Helpers
        module Constants
          TEMPLATE_TYPES = %i[gemspec gemfile rubocop ci rspec gitignore license version entry_point spec_helper runner client].freeze
          DEFAULT_RUBY_VERSION = '3.4'
          DEFAULT_LICENSE      = 'MIT'
          DEFAULT_AUTHOR       = 'Esity'
          DEFAULT_EMAIL        = 'matthewdiverson@gmail.com'
          DEFAULT_GEM_VERSION  = '0.1.0'

          GEMSPEC_TEMPLATE = <<~'ERB'
            # frozen_string_literal: true

            require_relative 'lib/legion/extensions/<%= gem_name_underscored %>/version'

            Gem::Specification.new do |spec|
              spec.name          = '<%= gem_name %>'
              spec.version       = Legion::Extensions::<%= module_name %>::VERSION
              spec.authors       = ['<%= author %>']
              spec.email         = ['<%= email %>']

              spec.summary       = 'Legion::Extensions::<%= module_name %>'
              spec.description   = '<%= description %>'
              spec.homepage      = 'https://github.com/LegionIO/<%= gem_name %>'
              spec.license       = '<%= license %>'
              spec.required_ruby_version = '>= <%= ruby_version %>'

              spec.metadata['homepage_uri']          = spec.homepage
              spec.metadata['source_code_uri']       = 'https://github.com/LegionIO/<%= gem_name %>'
              spec.metadata['changelog_uri']         = 'https://github.com/LegionIO/<%= gem_name %>'
              spec.metadata['documentation_uri']     = 'https://github.com/LegionIO/<%= gem_name %>'
              spec.metadata['bug_tracker_uri']       = 'https://github.com/LegionIO/<%= gem_name %>/issues'
              spec.metadata['rubygems_mfa_required'] = 'true'

              spec.files = Dir.chdir(File.expand_path(__dir__)) do
                `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
              end
              spec.require_paths = ['lib']

              spec.add_dependency 'legionio'
            <% extra_deps.each do |dep| -%>
              spec.add_dependency '<%= dep %>'
            <% end -%>

              spec.add_development_dependency 'rake'
              spec.add_development_dependency 'rspec', '~> 3.13'
              spec.add_development_dependency 'rspec_junit_formatter'
              spec.add_development_dependency 'rubocop', '~> 1.75'
              spec.add_development_dependency 'rubocop-rspec'
              spec.add_development_dependency 'simplecov'
            end
          ERB

          GEMFILE_TEMPLATE = <<~ERB
            # frozen_string_literal: true

            source 'https://rubygems.org'
            gemspec

            group :test do
              gem 'rake'
              gem 'rspec', '~> 3.13'
              gem 'rspec_junit_formatter'
              gem 'rubocop', '~> 1.75'
              gem 'rubocop-rspec'
              gem 'simplecov'
            end
          ERB

          RUBOCOP_TEMPLATE = <<~ERB
            AllCops:
              TargetRubyVersion: <%= ruby_version %>
              NewCops: enable
              SuggestExtensions: false

            Layout/LineLength:
              Max: 160

            Layout/SpaceAroundEqualsInParameterDefault:
              EnforcedStyle: space

            Layout/HashAlignment:
              EnforcedHashRocketStyle: table
              EnforcedColonStyle: table

            Metrics/MethodLength:
              Max: 50

            Metrics/ClassLength:
              Max: 1500

            Metrics/ModuleLength:
              Max: 1500

            Metrics/BlockLength:
              Max: 40

            Metrics/AbcSize:
              Max: 60

            Metrics/CyclomaticComplexity:
              Max: 15

            Metrics/PerceivedComplexity:
              Max: 17

            Style/Documentation:
              Enabled: false

            Style/SymbolArray:
              Enabled: true

            Style/FrozenStringLiteralComment:
              Enabled: true
              EnforcedStyle: always

            Naming/FileName:
              Enabled: false

            Naming/PredicateMethod:
              Enabled: false

            Naming/PredicatePrefix:
              Enabled: false
          ERB

          CI_TEMPLATE = <<~ERB
            name: CI
            on: [push, pull_request]
            jobs:
              ci:
                uses: LegionIO/.github/.github/workflows/ci.yml@main
          ERB

          RSPEC_TEMPLATE = <<~ERB
            --format documentation
            --color
            --require spec_helper
          ERB

          GITIGNORE_TEMPLATE = <<~ERB
            /.bundle/
            /.yardoc
            /_yardoc/
            /coverage/
            /doc/
            /pkg/
            /spec/reports/
            /tmp/

            # rspec failure tracking
            .rspec_status
          ERB

          LICENSE_TEMPLATE = <<~ERB
            MIT License

            Copyright (c) 2024 <%= author %>

            Permission is hereby granted, free of charge, to any person obtaining a copy
            of this software and associated documentation files (the "Software"), to deal
            in the Software without restriction, including without limitation the rights
            to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
            copies of the Software, and to permit persons to whom the Software is
            furnished to do so, subject to the following conditions:

            The above copyright notice and this permission notice shall be included in all
            copies or substantial portions of the Software.

            THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
            IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
            FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
            AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
            LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
            OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
            SOFTWARE.
          ERB

          VERSION_TEMPLATE = <<~ERB
            # frozen_string_literal: true

            module Legion
              module Extensions
                module <%= module_name %>
                  VERSION = '<%= gem_version %>'
                end
              end
            end
          ERB

          ENTRY_POINT_TEMPLATE = <<~ERB
            # frozen_string_literal: true

            require 'securerandom'
            require_relative '<%= gem_name_underscored %>/version'
            require_relative '<%= gem_name_underscored %>/helpers/constants'
            <% helpers.each do |h| -%>
            require_relative '<%= gem_name_underscored %>/helpers/<%= h %>'
            <% end -%>
            <% runner_names.each do |r| -%>
            require_relative '<%= gem_name_underscored %>/runners/<%= r %>'
            <% end -%>
            require_relative '<%= gem_name_underscored %>/client'

            module Legion
              module Extensions
                module <%= module_name %>
                  extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
                end
              end
            end
          ERB

          SPEC_HELPER_TEMPLATE = <<~ERB
            # frozen_string_literal: true

            require 'bundler/setup'
            require 'legion/extensions/<%= gem_name_underscored %>'

            # Stub Legion::Logging when running standalone
            unless defined?(Legion::Logging)
              module Legion
                module Logging
                  def self.info(*); end
                  def self.debug(*); end
                  def self.warn(*); end
                  def self.error(*); end
                end
              end
            end

            RSpec.configure do |config|
              config.example_status_persistence_file_path = '.rspec_status'
              config.disable_monkey_patching!
              config.expect_with(:rspec) { |c| c.syntax = :expect }
            end
          ERB

          RUNNER_TEMPLATE = <<~ERB
            # frozen_string_literal: true

            module Legion
              module Extensions
                module <%= module_name %>
                  module Runners
                    module <%= runner_class %>
                      extend self
            <% methods.each do |m| -%>

                      def <%= m[:name] %>(<%= m[:params].join(', ') %><%= m[:params].empty? ? '**' : ', **' %>)
                        Legion::Logging.debug "[<%= gem_name_underscored %>] <%= m[:name] %> called"
                        { success: true }
                      end
            <% end -%>
                    end
                  end
                end
              end
            end
          ERB

          CLIENT_TEMPLATE = <<~ERB
            # frozen_string_literal: true

            module Legion
              module Extensions
                module <%= module_name %>
                  class Client
            <% runner_names.each do |r| -%>
                    include Runners::<%= r.split('_').map(&:capitalize).join %>
            <% end -%>

                    def initialize(base_path: Dir.pwd)
                      @base_path = base_path
                    end
                  end
                end
              end
            end
          ERB

          TEMPLATE_MAP = {
            gemspec:     GEMSPEC_TEMPLATE,
            gemfile:     GEMFILE_TEMPLATE,
            rubocop:     RUBOCOP_TEMPLATE,
            ci:          CI_TEMPLATE,
            rspec:       RSPEC_TEMPLATE,
            gitignore:   GITIGNORE_TEMPLATE,
            license:     LICENSE_TEMPLATE,
            version:     VERSION_TEMPLATE,
            entry_point: ENTRY_POINT_TEMPLATE,
            spec_helper: SPEC_HELPER_TEMPLATE,
            runner:      RUNNER_TEMPLATE,
            client:      CLIENT_TEMPLATE
          }.freeze
        end
      end
    end
  end
end
