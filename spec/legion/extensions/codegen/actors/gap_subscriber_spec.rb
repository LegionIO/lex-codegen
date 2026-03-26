# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Codegen::Actor::GapSubscriber do
  let(:actor_instance) do
    obj = Object.new
    obj.extend(described_class)
    obj
  end

  let(:payload) do
    { gap_id: 'gap_001', gap_type: 'unmatched_intent', intent: 'greet user', occurrence_count: 3, priority: 0.8 }
  end

  describe '#action' do
    it 'calls FromGap.generate' do
      expect(Legion::Extensions::Codegen::Runners::FromGap).to receive(:generate).and_return({ success: false, reason: :llm_unavailable })
      actor_instance.action(payload)
    end

    it 'returns generation result' do
      allow(Legion::Extensions::Codegen::Runners::FromGap).to receive(:generate).and_return({ success: true, generation_id: 'gen_001' })
      msg_double = instance_double(Legion::Extensions::Codegen::Transport::Messages::CodeReviewRequested, publish: true)
      allow(Legion::Extensions::Codegen::Transport::Messages::CodeReviewRequested).to receive(:new).and_return(msg_double)
      result = actor_instance.action(payload)
      expect(result[:success]).to be true
    end

    it 'publishes code review request on success' do
      allow(Legion::Extensions::Codegen::Runners::FromGap).to receive(:generate).and_return({ success: true, generation_id: 'gen_001' })
      msg_double = instance_double(Legion::Extensions::Codegen::Transport::Messages::CodeReviewRequested, publish: true)
      expect(Legion::Extensions::Codegen::Transport::Messages::CodeReviewRequested).to receive(:new).with(generation: hash_including(success: true)).and_return(msg_double)
      actor_instance.action(payload)
    end

    it 'does not publish on failure' do
      allow(Legion::Extensions::Codegen::Runners::FromGap).to receive(:generate).and_return({ success: false, reason: :llm_unavailable })
      expect(Legion::Extensions::Codegen::Transport::Messages::CodeReviewRequested).not_to receive(:new)
      actor_instance.action(payload)
    end

    it 'rescues errors and returns failure hash' do
      allow(Legion::Extensions::Codegen::Runners::FromGap).to receive(:generate).and_raise(RuntimeError, 'boom')
      result = actor_instance.action(payload)
      expect(result[:success]).to be false
      expect(result[:error]).to eq('boom')
    end
  end

  describe '#normalize_gap' do
    it 'normalizes payload keys' do
      result = actor_instance.send(:normalize_gap, payload)
      expect(result[:id]).to eq('gap_001')
      expect(result[:type]).to eq(:unmatched_intent)
      expect(result[:intent]).to eq('greet user')
      expect(result[:occurrence_count]).to eq(3)
      expect(result[:priority]).to eq(0.8)
    end

    it 'defaults occurrence_count to 1 and priority to 0.5' do
      result = actor_instance.send(:normalize_gap, { gap_id: 'g', gap_type: 'x', intent: 'y' })
      expect(result[:occurrence_count]).to eq(1)
      expect(result[:priority]).to eq(0.5)
    end
  end

  describe 'Apollo corroboration' do
    let(:apollo_module) do
      Module.new do
        def self.ingest(**) = { success: true }
        def self.retrieve(**) = { results: [{ source: { provider: 'node-a' } }, { source: { provider: 'node-b' } }] }
      end
    end

    before do
      allow(Legion::Extensions::Codegen::Runners::FromGap).to receive(:generate).and_return({ success: false })
    end

    context 'when Apollo is available and corroboration enabled' do
      before do
        stub_const('Legion::Apollo', apollo_module)
        allow(Legion::Settings).to receive(:dig).and_return(nil)
        allow(Legion::Settings).to receive(:dig).with(:codegen, :self_generate, :corroboration, :enabled).and_return(true)
        allow(Legion::Settings).to receive(:dig).with(:codegen, :self_generate, :corroboration, :priority_boost_per_agent).and_return(0.15)
        allow(Legion::Settings).to receive(:dig).with(:codegen, :self_generate, :corroboration, :apollo_query_before_generate).and_return(true)
        allow(Legion::Settings).to receive(:dig).with(:codegen, :self_generate, :corroboration, :min_agents).and_return(2)
        allow(Legion::Settings).to receive(:dig).with(:node, :name).and_return('test-node')
      end

      it 'ingests the gap into Apollo' do
        expect(Legion::Apollo).to receive(:ingest).with(
          content: 'capability_gap: greet user (type: unmatched_intent)',
          tags:    [:capability_gap, :unmatched_intent, :self_generate],
          scope:   :global,
          source:  { provider: 'test-node', channel: 'gap_detector' }
        )
        actor_instance.action(payload)
      end

      it 'queries Apollo for corroboration' do
        expect(Legion::Apollo).to receive(:retrieve).with(
          query: 'capability_gap: greet user',
          scope: :global,
          limit: 10
        )
        actor_instance.action(payload)
      end

      it 'boosts priority when corroboration count meets min_agents' do
        expect(Legion::Extensions::Codegen::Runners::FromGap).to receive(:generate) do |gap:|
          expect(gap[:priority]).to eq([0.8 + (0.15 * 2), 1.0].min)
          { success: false }
        end
        actor_instance.action(payload)
      end

      it 'does not boost priority when corroboration count is below min_agents' do
        allow(Legion::Settings).to receive(:dig).with(:codegen, :self_generate, :corroboration, :min_agents).and_return(5)
        expect(Legion::Extensions::Codegen::Runners::FromGap).to receive(:generate) do |gap:|
          expect(gap[:priority]).to eq(0.8)
          { success: false }
        end
        actor_instance.action(payload)
      end

      it 'caps priority at 1.0' do
        allow(Legion::Settings).to receive(:dig).with(:codegen, :self_generate, :corroboration, :priority_boost_per_agent).and_return(0.5)
        allow(Legion::Settings).to receive(:dig).with(:codegen, :self_generate, :corroboration, :min_agents).and_return(1)
        expect(Legion::Extensions::Codegen::Runners::FromGap).to receive(:generate) do |gap:|
          expect(gap[:priority]).to eq(1.0)
          { success: false }
        end
        actor_instance.action(payload)
      end

      it 'counts unique providers only' do
        dup_apollo = Module.new do
          def self.ingest(**) = { success: true }
          def self.retrieve(**)
            { results: [{ source: { provider: 'same-node' } }, { source: { provider: 'same-node' } }, { source: { provider: 'other' } }] }
          end
        end
        stub_const('Legion::Apollo', dup_apollo)
        allow(Legion::Settings).to receive(:dig).with(:codegen, :self_generate, :corroboration, :min_agents).and_return(2)
        expect(Legion::Extensions::Codegen::Runners::FromGap).to receive(:generate) do |gap:|
          expect(gap[:priority]).to eq([0.8 + (0.15 * 2), 1.0].min)
          { success: false }
        end
        actor_instance.action(payload)
      end
    end

    context 'when Apollo is unavailable' do
      it 'generates without boost or error' do
        expect(Legion::Extensions::Codegen::Runners::FromGap).to receive(:generate) do |gap:|
          expect(gap[:priority]).to eq(0.8)
          { success: false, reason: :llm_unavailable }
        end
        result = actor_instance.action(payload)
        expect(result).to have_key(:success)
      end
    end

    context 'when corroboration is disabled' do
      before do
        stub_const('Legion::Apollo', apollo_module)
        allow(Legion::Settings).to receive(:dig).and_return(nil)
        allow(Legion::Settings).to receive(:dig).with(:codegen, :self_generate, :corroboration, :enabled).and_return(false)
      end

      it 'does not ingest or query Apollo' do
        expect(Legion::Apollo).not_to receive(:ingest)
        expect(Legion::Apollo).not_to receive(:retrieve)
        actor_instance.action(payload)
      end
    end

    context 'when Apollo query fails' do
      before do
        failing_apollo = Module.new do
          def self.ingest(**) = { success: true }
          def self.retrieve(**) = raise('connection refused')
        end
        stub_const('Legion::Apollo', failing_apollo)
        allow(Legion::Settings).to receive(:dig).and_return(nil)
        allow(Legion::Settings).to receive(:dig).with(:codegen, :self_generate, :corroboration, :enabled).and_return(true)
        allow(Legion::Settings).to receive(:dig).with(:codegen, :self_generate, :corroboration, :apollo_query_before_generate).and_return(true)
        allow(Legion::Settings).to receive(:dig).with(:codegen, :self_generate, :corroboration, :min_agents).and_return(2)
      end

      it 'falls back to zero corroboration without crashing' do
        expect(Legion::Extensions::Codegen::Runners::FromGap).to receive(:generate) do |gap:|
          expect(gap[:priority]).to eq(0.8)
          { success: false }
        end
        actor_instance.action(payload)
      end
    end

    context 'when query_before_generate is false' do
      before do
        stub_const('Legion::Apollo', apollo_module)
        allow(Legion::Settings).to receive(:dig).and_return(nil)
        allow(Legion::Settings).to receive(:dig).with(:codegen, :self_generate, :corroboration, :enabled).and_return(true)
        allow(Legion::Settings).to receive(:dig).with(:codegen, :self_generate, :corroboration, :apollo_query_before_generate).and_return(false)
      end

      it 'ingests but does not query Apollo' do
        expect(Legion::Apollo).to receive(:ingest)
        expect(Legion::Apollo).not_to receive(:retrieve)
        actor_instance.action(payload)
      end
    end
  end
end
