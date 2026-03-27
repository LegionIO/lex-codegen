# frozen_string_literal: true

module Legion
  module Extensions
    module Codegen
      module Helpers
        module GeneratedRegistry
          module_function

          def persist(generation:)
            record = {
              id:            generation[:id],
              gap_id:        generation[:gap_id],
              gap_type:      generation[:gap_type],
              tier:          generation[:tier],
              name:          generation[:name],
              file_path:     generation[:file_path],
              spec_path:     generation[:spec_path],
              status:        'pending',
              confidence:    generation[:confidence] || 0.0,
              attempt_count: generation[:attempt_count] || 0,
              created_at:    Time.now,
              usage_count:   0
            }

            if db_available?
              db[:generated_functions].insert(record)
            else
              store[record[:id]] = record
            end

            record
          end

          def list(status: nil)
            if db_available?
              ds = db[:generated_functions]
              ds = ds.where(status: status) if status
              ds.all
            else
              records = store.values
              records = records.select { |r| r[:status] == status } if status
              records
            end
          end

          def get(id:)
            if db_available?
              db[:generated_functions].where(id: id).first
            else
              store[id]
            end
          end

          def update_status(id:, status:)
            updates = { status: status }
            updates[:approved_at] = Time.now if status == 'approved'

            if db_available?
              db[:generated_functions].where(id: id).update(updates)
            elsif store[id]
              store[id].merge!(updates)
            end
          end

          def record_usage(id:)
            if db_available?
              db[:generated_functions].where(id: id).update(
                usage_count:  Sequel.expr(:usage_count) + 1,
                last_used_at: Time.now
              )
            elsif store[id]
              store[id][:usage_count] = (store[id][:usage_count] || 0) + 1
              store[id][:last_used_at] = Time.now
            end
          end

          def load_on_boot
            approved = list(status: 'approved')
            loaded = 0

            approved.each do |record|
              next unless record[:file_path] && ::File.exist?(record[:file_path])

              begin
                Kernel.load(record[:file_path])
                loaded += 1
              rescue StandardError => e
                log.warn("GeneratedRegistry: failed to load #{record[:file_path]}: #{e.message}")
              end
            end

            loaded
          end

          def reset!
            @store = {}
          end

          def store
            @store ||= {}
          end

          def log
            return Legion::Logging if defined?(Legion::Logging)

            @log ||= Object.new.tap do |nl|
              %i[debug info warn error fatal].each { |m| nl.define_singleton_method(m) { |*| nil } }
            end
          end

          def db_available?
            defined?(Legion::Data::Local) && Legion::Data::Local.respond_to?(:db) && !Legion::Data::Local.db.nil?
          rescue StandardError => e
            log.debug("db_available? check failed: #{e.message}")
            false
          end

          def db
            Legion::Data::Local.db
          end
        end
      end
    end
  end
end
