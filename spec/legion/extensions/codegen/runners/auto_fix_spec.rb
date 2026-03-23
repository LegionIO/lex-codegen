# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Codegen::Runners::AutoFix do
  describe '#auto_fix' do
    context 'when Legion::LLM is not available' do
      it 'returns llm_unavailable' do
        result = described_class.auto_fix(
          gem_name: 'lex-fake', runner_class: 'FakeRunner',
          error_class: 'NoMethodError', backtraces: ['line1']
        )
        expect(result[:success]).to be false
        expect(result[:reason]).to eq(:llm_unavailable)
      end
    end

    context 'when gem is not found' do
      before do
        stub_const('Legion::LLM', Module.new { def self.chat(**) = { content: 'no patch' } })
        allow(Gem::Specification).to receive(:find_by_name) { raise Gem::MissingSpecError.new('lex-nonexistent', Gem::Requirement.new) }
      end

      it 'returns gem_not_found' do
        result = described_class.auto_fix(
          gem_name: 'lex-nonexistent', runner_class: 'FakeRunner',
          error_class: 'NoMethodError', backtraces: ['line1']
        )
        expect(result[:success]).to be false
        expect(result[:reason]).to eq(:gem_not_found)
      end
    end
  end

  describe '#approve_fix' do
    context 'when Legion::Data::Local is not available' do
      before { hide_const('Legion::Data::Local') }

      it 'returns data_unavailable' do
        result = described_class.approve_fix(fix_id: 'abc')
        expect(result[:success]).to be false
        expect(result[:reason]).to eq(:data_unavailable)
      end
    end
  end

  describe '#reject_fix' do
    context 'when Legion::Data::Local is not available' do
      before { hide_const('Legion::Data::Local') }

      it 'returns data_unavailable' do
        result = described_class.reject_fix(fix_id: 'abc')
        expect(result[:success]).to be false
        expect(result[:reason]).to eq(:data_unavailable)
      end
    end
  end

  describe '#list_fixes' do
    context 'when Legion::Data::Local is not available' do
      before { hide_const('Legion::Data::Local') }

      it 'returns empty list' do
        result = described_class.list_fixes
        expect(result[:fixes]).to eq([])
      end
    end
  end

  describe '#build_fix_prompt' do
    it 'includes source code and error information' do
      prompt = described_class.send(:build_fix_prompt, 'def foo; end', 'NoMethodError',
                                    ["file.rb:10:in 'bar'"])
      expect(prompt).to include('def foo; end')
      expect(prompt).to include('NoMethodError')
      expect(prompt).to include('file.rb:10')
    end
  end
end
