# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Codegen::Helpers::GeneratedRegistry do
  before { described_class.reset! }

  let(:generation) do
    {
      id:         'gen_001',
      gap_id:     'gap_abc',
      gap_type:   'unmatched_intent',
      tier:       'simple',
      name:       'Legion::Generated::Greeter',
      file_path:  '/tmp/test_generated.rb',
      spec_path:  '/tmp/test_generated_spec.rb',
      confidence: 0.95
    }
  end

  describe '.persist' do
    it 'stores a generation record' do
      described_class.persist(generation: generation)
      expect(described_class.list.size).to eq(1)
    end

    it 'returns the stored record' do
      result = described_class.persist(generation: generation)
      expect(result[:id]).to eq('gen_001')
      expect(result[:status]).to eq('pending')
    end
  end

  describe '.list' do
    before { described_class.persist(generation: generation) }

    it 'returns all records' do
      expect(described_class.list.size).to eq(1)
    end

    it 'filters by status' do
      expect(described_class.list(status: 'pending').size).to eq(1)
      expect(described_class.list(status: 'approved').size).to eq(0)
    end
  end

  describe '.get' do
    before { described_class.persist(generation: generation) }

    it 'returns record by id' do
      record = described_class.get(id: 'gen_001')
      expect(record[:name]).to eq('Legion::Generated::Greeter')
    end

    it 'returns nil for missing id' do
      expect(described_class.get(id: 'missing')).to be_nil
    end
  end

  describe '.update_status' do
    before { described_class.persist(generation: generation) }

    it 'updates the status' do
      described_class.update_status(id: 'gen_001', status: 'approved')
      record = described_class.get(id: 'gen_001')
      expect(record[:status]).to eq('approved')
    end
  end

  describe '.record_usage' do
    before { described_class.persist(generation: generation) }

    it 'increments usage_count' do
      described_class.record_usage(id: 'gen_001')
      record = described_class.get(id: 'gen_001')
      expect(record[:usage_count]).to eq(1)
    end
  end

  describe '.reset!' do
    it 'clears all records' do
      described_class.persist(generation: generation)
      described_class.reset!
      expect(described_class.list).to be_empty
    end
  end
end
