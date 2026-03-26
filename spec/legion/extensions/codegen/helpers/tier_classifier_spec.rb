# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Codegen::Helpers::TierClassifier do
  describe '.classify' do
    it 'returns :simple for low occurrence count' do
      gap = { occurrence_count: 5 }
      expect(described_class.classify(gap: gap)).to eq(:simple)
    end

    it 'returns :simple at the threshold boundary' do
      gap = { occurrence_count: 10 }
      expect(described_class.classify(gap: gap)).to eq(:simple)
    end

    it 'returns :complex for high occurrence count' do
      gap = { occurrence_count: 11 }
      expect(described_class.classify(gap: gap)).to eq(:complex)
    end

    it 'returns :simple when count is nil' do
      gap = {}
      expect(described_class.classify(gap: gap)).to eq(:simple)
    end

    it 'reads thresholds from Settings when available' do
      allow(Legion::Settings).to receive(:dig).and_return(nil)
      allow(Legion::Settings).to receive(:dig).with(:codegen, :self_generate, :tier, :simple_max_occurrences).and_return(3)
      gap = { occurrence_count: 4 }
      expect(described_class.classify(gap: gap)).to eq(:complex)
    end

    it 'falls back to default threshold of 10 when Settings unavailable' do
      allow(Legion::Settings).to receive(:dig).and_return(nil)
      gap = { occurrence_count: 10 }
      expect(described_class.classify(gap: gap)).to eq(:simple)
    end
  end
end
