# frozen_string_literal: true

module Legion
  module Extensions
    module Codegen
      module Runners
        module ReviewHandler
          extend self

          def handle_verdict(review:)
            generation_id = review[:generation_id]
            record = Helpers::GeneratedRegistry.get(id: generation_id)
            return { success: false, reason: :not_found, generation_id: generation_id } unless record

            case review[:verdict]
            when :approve
              approve(record, review)
            when :reject
              park(record, 'rejected', review[:issues])
            when :revise
              handle_revise(record, review)
            else
              { success: false, reason: :unknown_verdict, verdict: review[:verdict] }
            end
          rescue StandardError => e
            { success: false, reason: :handler_error, error: e.message }
          end

          private

          def log
            return Legion::Logging if defined?(Legion::Logging)

            @log ||= Object.new.tap do |nl|
              %i[debug info warn error fatal].each { |m| nl.define_singleton_method(m) { |*| nil } }
            end
          end

          def approve(record, review)
            Helpers::GeneratedRegistry.update_status(id: record[:id], status: 'approved')

            if defined?(Legion::MCP::Server) && record[:file_path] && File.exist?(record[:file_path])
              begin
                Kernel.load(record[:file_path])
              rescue StandardError => e
                log.warn("ReviewHandler: load failed: #{e.message}")
              end
            end

            { success: true, action: :approved, generation_id: record[:id], confidence: review[:confidence] }
          end

          def park(record, reason, issues = nil)
            Helpers::GeneratedRegistry.update_status(id: record[:id], status: 'parked')
            { success: true, action: :parked, generation_id: record[:id], reason: reason, issues: issues }
          end

          def handle_revise(record, review)
            max_retries = if defined?(Legion::Settings)
                            Legion::Settings.dig(:codegen, :self_generate, :validation, :max_retries) || 2
                          else
                            2
                          end

            return park(record, 'max_retries_exceeded', review[:issues]) if (record[:attempt_count] || 0) >= max_retries

            Helpers::GeneratedRegistry.update_status(id: record[:id], status: 'pending')
            { success: true, action: :retry_queued, generation_id: record[:id], attempt: (record[:attempt_count] || 0) + 1 }
          end
        end
      end
    end
  end
end
