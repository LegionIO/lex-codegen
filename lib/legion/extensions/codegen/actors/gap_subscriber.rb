# frozen_string_literal: true

return unless defined?(Legion::Extensions::Actors::Subscription)

module Legion
  module Extensions
    module Codegen
      module Actor
        class GapSubscriber < Legion::Extensions::Actors::Subscription
          QUEUE = Transport::Queues::GapDetected if defined?(Transport::Queues::GapDetected)

          def runner_class = self.class
          def runner_function = 'action'

          def action(payload)
            gap = normalize_gap(payload)

            ingest_gap_to_apollo(gap)
            corroboration_count = query_corroboration(gap)
            gap = boost_priority(gap, corroboration_count) if corroboration_count >= min_agents

            result = Runners::FromGap.generate(gap: gap)

            Transport::Messages::CodeReviewRequested.new(generation: result).publish if result[:success] && defined?(Transport::Messages::CodeReviewRequested)

            result
          rescue StandardError => e
            log.warn("GapSubscriber failed: #{e.message}")
            { success: false, error: e.message }
          end

          private

          def normalize_gap(payload)
            {
              id:               payload[:gap_id] || payload[:id],
              type:             (payload[:gap_type] || payload[:type])&.to_sym,
              intent:           payload[:intent],
              occurrence_count: payload[:occurrence_count] || 1,
              priority:         payload[:priority] || 0.5,
              metadata:         payload[:metadata] || {}
            }
          end

          def ingest_gap_to_apollo(gap)
            return unless defined?(Legion::Apollo) && corroboration_enabled?

            Legion::Apollo.ingest(
              content: "capability_gap: #{gap[:intent]} (type: #{gap[:type]})",
              tags:    [:capability_gap, gap[:type], :self_generate],
              scope:   :global,
              source:  { provider: node_name, channel: 'gap_detector' }
            )
          rescue StandardError => e
            log.debug("GapSubscriber: Apollo ingest failed: #{e.message}")
          end

          def query_corroboration(gap)
            return 0 unless defined?(Legion::Apollo) && corroboration_enabled? && query_before_generate?

            result = Legion::Apollo.retrieve(
              query: "capability_gap: #{gap[:intent]}",
              scope: :global,
              limit: 10
            )

            results = result[:results] || []
            results.map { |r| r.dig(:source, :provider) }.compact.uniq.size
          rescue StandardError => e
            log.debug("GapSubscriber: Apollo query failed: #{e.message}")
            0
          end

          def boost_priority(gap, corroboration_count)
            return gap if corroboration_count.zero?

            boost = priority_boost_per_agent * corroboration_count
            gap.merge(priority: [gap[:priority] + boost, 1.0].min)
          end

          def corroboration_enabled?
            return false unless defined?(Legion::Settings)

            Legion::Settings.dig(:codegen, :self_generate, :corroboration, :enabled) == true
          end

          def query_before_generate?
            return true unless defined?(Legion::Settings)

            Legion::Settings.dig(:codegen, :self_generate, :corroboration, :apollo_query_before_generate) != false
          end

          def min_agents
            if defined?(Legion::Settings)
              Legion::Settings.dig(:codegen, :self_generate, :corroboration, :min_agents) || 2
            else
              2
            end
          end

          def priority_boost_per_agent
            if defined?(Legion::Settings)
              Legion::Settings.dig(:codegen, :self_generate, :corroboration, :priority_boost_per_agent) || 0.15
            else
              0.15
            end
          end

          def node_name
            defined?(Legion::Settings) ? (Legion::Settings.dig(:node, :name) || 'unknown') : 'unknown'
          end

          def log
            return Legion::Logging if defined?(Legion::Logging)

            @log ||= Object.new.tap do |nl|
              %i[debug info warn error fatal].each { |m| nl.define_singleton_method(m) { |*| nil } }
            end
          end
        end
      end
    end
  end
end
