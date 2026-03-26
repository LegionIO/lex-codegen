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
  end

  describe 'Apollo corroboration' do
    let(:payload) do
      { gap_id: 'gap_001', gap_type: 'unmatched_intent', intent: 'greet user', occurrence_count: 3, priority: 0.8 }
    end

    context 'when Apollo is available and corroboration enabled' do
      before do
        stub_const('Legion::Apollo', Module.new do
          def self.ingest(**) = { success: true }
          def self.retrieve(**) = { results: [{ source: { provider: 'other-node' } }, { source: { provider: 'third-node' } }] }
        end)
        allow(Legion::Settings).to receive(:dig).and_return(nil)
        allow(Legion::Settings).to receive(:dig).with(:codegen, :self_generate, :corroboration, :enabled).and_return(true)
        allow(Legion::Settings).to receive(:dig).with(:codegen, :self_generate, :corroboration, :priority_boost_per_agent).and_return(0.15)
        allow(Legion::Settings).to receive(:dig).with(:codegen, :self_generate, :corroboration, :apollo_query_before_generate).and_return(true)
      end

      it 'ingests the gap into Apollo' do
        allow(Legion::Extensions::Codegen::Runners::FromGap).to receive(:generate).and_return({ success: false })
        expect(Legion::Apollo).to receive(:ingest).with(hash_including(scope: :global))
        actor_instance.action(payload)
      end

      it 'queries Apollo for corroboration' do
        allow(Legion::Extensions::Codegen::Runners::FromGap).to receive(:generate).and_return({ success: false })
        expect(Legion::Apollo).to receive(:retrieve)
        actor_instance.action(payload)
      end
    end

    context 'when Apollo is unavailable' do
      it 'generates without error' do
        allow(Legion::Extensions::Codegen::Runners::FromGap).to receive(:generate).and_return({ success: false, reason: :llm_unavailable })
        result = actor_instance.action(payload)
        expect(result).to have_key(:success)
      end
    end
  end
end
