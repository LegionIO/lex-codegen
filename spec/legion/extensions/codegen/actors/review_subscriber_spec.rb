# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Codegen::Actor::ReviewSubscriber do
  let(:actor_instance) do
    obj = Object.new
    obj.extend(described_class)
    obj
  end

  before { Legion::Extensions::Codegen::Helpers::GeneratedRegistry.reset! }

  describe '#action' do
    let(:payload) do
      { generation_id: 'gen_001', verdict: 'approve', confidence: 0.95, issues: [] }
    end

    it 'calls ReviewHandler.handle_verdict' do
      expect(Legion::Extensions::Codegen::Runners::ReviewHandler).to receive(:handle_verdict).and_return({ success: true })
      actor_instance.action(payload)
    end

    it 'converts verdict to symbol' do
      expect(Legion::Extensions::Codegen::Runners::ReviewHandler).to receive(:handle_verdict).with(
        review: hash_including(verdict: :approve)
      ).and_return({ success: true })
      actor_instance.action(payload)
    end
  end
end
