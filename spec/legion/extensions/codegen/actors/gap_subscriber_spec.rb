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
end
