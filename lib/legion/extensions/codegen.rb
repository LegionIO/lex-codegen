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
require_relative 'codegen/runners/from_gap'
require_relative 'codegen/runners/review_handler'
require_relative 'codegen/client'

if defined?(Legion::Transport::Exchange)
  require_relative 'codegen/transport/exchanges/codegen'
  require_relative 'codegen/transport/queues/gap_detected'
  require_relative 'codegen/transport/queues/review_completed'
  require_relative 'codegen/transport/messages/gap_detected'
  require_relative 'codegen/transport/messages/code_review_requested'
end

require_relative 'codegen/actors/gap_subscriber'
require_relative 'codegen/actors/review_subscriber'

module Legion
  module Extensions
    module Codegen
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core, false

      def self.remote_invocable?
        false
      end
    end
  end
end

if defined?(Legion::Data::Local)
  Legion::Data::Local.register_migrations(
    name: :codegen,
    path: File.join(__dir__, 'codegen', 'local_migrations')
  )
end
