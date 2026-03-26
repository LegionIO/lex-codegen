# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Codegen::Runners::FromGap do
  describe '.generate' do
    let(:simple_gap) do
      { id: 'gap_001', type: :unmatched_intent, intent: 'greet user', occurrence_count: 3, priority: 0.8 }
    end

    let(:complex_gap) do
      { id: 'gap_002', type: :unmatched_intent, intent: 'manage deployments', occurrence_count: 15, priority: 0.9 }
    end

    it 'classifies simple gaps and calls generate_runner_method' do
      expect(described_class).to receive(:generate_runner_method).with(gap: simple_gap).and_return({ success: true })
      described_class.generate(gap: simple_gap)
    end

    it 'classifies complex gaps and calls generate_full_extension' do
      expect(described_class).to receive(:generate_full_extension).with(gap: complex_gap).and_return({ success: true })
      described_class.generate(gap: complex_gap)
    end

    it 'returns generation metadata on success' do
      allow(described_class).to receive(:generate_runner_method).and_return({
        success: true, generation_id: 'gen_001', file_path: '/tmp/test.rb'
      })
      result = described_class.generate(gap: simple_gap)
      expect(result[:success]).to be true
    end
  end

  describe '.generate_runner_method' do
    let(:gap) { { id: 'gap_001', type: :unmatched_intent, intent: 'greet user', priority: 0.8 } }

    context 'when LLM is unavailable' do
      it 'returns failure' do
        result = described_class.generate_runner_method(gap: gap)
        expect(result[:success]).to be false
        expect(result[:reason]).to eq(:llm_unavailable)
      end
    end

    context 'when LLM is available' do
      let(:llm_response) do
        double('response', content: <<~RUBY)
          # frozen_string_literal: true

          module Legion
            module Generated
              module Greeter
                extend self

                def greet(name: 'world')
                  { success: true, greeting: "Hello \#{name}" }
                end
              end
            end
          end
        RUBY
      end

      before do
        stub_const('Legion::LLM', Module.new {
          def self.chat(**) = nil
          def self.respond_to?(m, *) = m == :chat ? true : super
        })
        allow(Legion::LLM).to receive(:chat).and_return(llm_response)
      end

      it 'calls LLM and returns success' do
        result = described_class.generate_runner_method(gap: gap)
        expect(result[:success]).to be true
        expect(result[:generation_id]).to be_a(String)
      end
    end
  end

  describe '.generate_full_extension' do
    let(:gap) { { id: 'gap_002', intent: 'manage deployments', occurrence_count: 15 } }

    context 'when Generate runner is available' do
      it 'delegates to scaffold_extension' do
        expect(Legion::Extensions::Codegen::Runners::Generate).to receive(:scaffold_extension).and_return({
          success: true, path: '/tmp/lex-deploy', files_created: 10
        })
        result = described_class.generate_full_extension(gap: gap)
        expect(result[:success]).to be true
      end
    end
  end
end
