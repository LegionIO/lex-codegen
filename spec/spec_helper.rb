# frozen_string_literal: true

require 'bundler/setup'
require 'legion/logging'
require 'legion/json'
require 'legion/cache'
require 'legion/crypt'
require 'legion/data'
require 'legion/settings'
require 'legion/transport'
require 'legion/extensions/codegen'

# Stub Legion::Extensions::Helpers::Lex when running standalone
unless defined?(Legion::Extensions::Helpers::Lex)
  module Legion
    module Extensions
      module Helpers
        module Lex
          def self.included(base)
            base.extend(ClassMethods)
          end

          module ClassMethods
          end
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!
  config.expect_with(:rspec) { |c| c.syntax = :expect }
end
