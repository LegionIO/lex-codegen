# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Codegen::Runners::ReviewHandler do
  before { Legion::Extensions::Codegen::Helpers::GeneratedRegistry.reset! }

  let(:generation) do
    {
      id: 'gen_001', gap_id: 'gap_abc', gap_type: 'unmatched_intent',
      tier: 'simple', name: 'Greeter', file_path: '/tmp/gen.rb',
      spec_path: '/tmp/gen_spec.rb', confidence: 0.95
    }
  end

  before do
    Legion::Extensions::Codegen::Helpers::GeneratedRegistry.persist(generation: generation)
  end

  describe '.handle_verdict' do
    it 'approves when verdict is :approve' do
      review = { generation_id: 'gen_001', verdict: :approve, confidence: 0.95 }
      result = described_class.handle_verdict(review: review)
      expect(result[:success]).to be true
      expect(result[:action]).to eq(:approved)
    end

    it 'updates registry status to approved' do
      review = { generation_id: 'gen_001', verdict: :approve, confidence: 0.95 }
      described_class.handle_verdict(review: review)
      record = Legion::Extensions::Codegen::Helpers::GeneratedRegistry.get(id: 'gen_001')
      expect(record[:status]).to eq('approved')
    end

    it 'parks when verdict is :reject' do
      review = { generation_id: 'gen_001', verdict: :reject, confidence: 0.1, issues: ['dangerous'] }
      result = described_class.handle_verdict(review: review)
      expect(result[:success]).to be true
      expect(result[:action]).to eq(:parked)
    end

    it 'retries when verdict is :revise and under max_retries' do
      review = { generation_id: 'gen_001', verdict: :revise, confidence: 0.4, issues: ['needs work'] }
      result = described_class.handle_verdict(review: review)
      expect(result[:success]).to be true
      expect(result[:action]).to eq(:retry_queued)
    end

    it 'parks when verdict is :revise but at max_retries' do
      # Set attempt_count to max
      Legion::Extensions::Codegen::Helpers::GeneratedRegistry.reset!
      gen = generation.merge(attempt_count: 2)
      Legion::Extensions::Codegen::Helpers::GeneratedRegistry.persist(generation: gen)

      review = { generation_id: 'gen_001', verdict: :revise, confidence: 0.4 }
      allow(Legion::Settings).to receive(:dig).and_return(nil)
      allow(Legion::Settings).to receive(:dig).with(:codegen, :self_generate, :validation, :max_retries).and_return(2)
      result = described_class.handle_verdict(review: review)
      expect(result[:action]).to eq(:parked)
    end

    it 'returns failure for unknown generation_id' do
      review = { generation_id: 'missing', verdict: :approve }
      result = described_class.handle_verdict(review: review)
      expect(result[:success]).to be false
    end
  end
end
