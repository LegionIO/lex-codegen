# frozen_string_literal: true

require 'securerandom'
require_relative 'codegen/version'
require_relative 'codegen/helpers/constants'
require_relative 'codegen/helpers/template_engine'
require_relative 'codegen/helpers/spec_generator'
require_relative 'codegen/helpers/file_writer'
require_relative 'codegen/helpers/tier_classifier'
require_relative 'codegen/helpers/generated_registry'
require_relative 'codegen/runners/generate'
require_relative 'codegen/runners/template'
require_relative 'codegen/runners/validate'
require_relative 'codegen/runners/auto_fix'
require_relative 'codegen/client'

module Legion
  module Extensions
    module Codegen
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end

if defined?(Legion::Data::Local)
  Legion::Data::Local.register_migrations(
    name: :codegen,
    path: File.join(__dir__, 'codegen', 'local_migrations')
  )
end
