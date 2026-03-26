# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

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
        stub_const('Legion::LLM', Module.new do
          def self.chat(**) = nil
          def self.respond_to?(mth, *) = mth == :chat ? true : super
        end)
        allow(Legion::LLM).to receive(:chat).and_return(llm_response)
      end

      it 'calls LLM and returns success' do
        result = described_class.generate_runner_method(gap: gap)
        expect(result[:success]).to be true
        expect(result[:generation_id]).to be_a(String)
      end
    end
  end

  describe '.implement_stub' do
    let(:stub_file) { Tempfile.new(['stub', '.rb']) }
    let(:stub_content) { "# frozen_string_literal: true\n\nmodule Example; end\n" }
    let(:context) { { name: 'lex-focus', category: :cognition, description: 'attention focus', metaphor: 'spotlight' } }

    before do
      stub_file.write(stub_content)
      stub_file.rewind
    end
    after do
      stub_file.close
      stub_file.unlink
    end

    context 'when LLM is unavailable' do
      it 'returns llm_unavailable' do
        result = described_class.implement_stub(file_path: stub_file.path, context: context)
        expect(result[:success]).to be false
        expect(result[:reason]).to eq(:llm_unavailable)
      end
    end

    context 'when file path is outside the allowed output directory' do
      before do
        stub_const('Legion::LLM', Module.new do
          def self.chat(**) = nil
          def self.respond_to?(mth, *) = mth == :chat ? true : super
        end)
      end

      it 'returns path_not_allowed' do
        result = described_class.implement_stub(file_path: '/etc/passwd', context: context)
        expect(result[:success]).to be false
        expect(result[:reason]).to eq(:path_not_allowed)
      end

      it 'rejects traversal attempts' do
        result = described_class.implement_stub(file_path: '/tmp/../etc/hosts', context: context)
        expect(result[:success]).to be false
        expect(result[:reason]).to eq(:path_not_allowed)
      end
    end

    context 'when LLM is available' do
      let(:generated_code) { "# frozen_string_literal: true\n\nmodule Example\n  def run = { success: true }\nend\n" }
      let(:llm_response) { double('response', content: generated_code) }

      before do
        stub_const('Legion::LLM', Module.new do
          def self.chat(**) = nil
          def self.respond_to?(mth, *) = mth == :chat ? true : super
        end)
        allow(Legion::LLM).to receive(:chat).and_return(llm_response)
        allow(described_class).to receive(:allowed_stub_path?).and_return(true)
      end

      it 'returns success with generated code' do
        result = described_class.implement_stub(file_path: stub_file.path, context: context)
        expect(result[:success]).to be true
        expect(result[:code]).to include('module Example')
        expect(result[:file_path]).to eq(stub_file.path)
      end

      it 'reads the stub file' do
        allow(File).to receive(:read).and_call_original
        described_class.implement_stub(file_path: stub_file.path, context: context)
        expect(File).to have_received(:read).with(stub_file.path)
      end

      it 'includes context in prompt' do
        described_class.implement_stub(file_path: stub_file.path, context: context)
        expect(Legion::LLM).to have_received(:chat).with(
          hash_including(
            messages: a_collection_including(
              a_hash_including(role: 'user', content: a_string_including('attention focus'))
            )
          )
        )
      end

      it 'includes metaphor in prompt when present' do
        described_class.implement_stub(file_path: stub_file.path, context: context)
        expect(Legion::LLM).to have_received(:chat).with(
          hash_including(
            messages: a_collection_including(
              a_hash_including(role: 'user', content: a_string_including('spotlight'))
            )
          )
        )
      end

      it 'extracts code from markdown fences' do
        fenced = "Here's the code:\n```ruby\n# frozen_string_literal: true\n\nreal_code\n```\n"
        allow(llm_response).to receive(:content).and_return(fenced)
        result = described_class.implement_stub(file_path: stub_file.path, context: context)
        expect(result[:code]).to include('real_code')
        expect(result[:code]).not_to include('```')
      end

      it 'returns empty response failure when LLM returns empty string' do
        allow(llm_response).to receive(:content).and_return('')
        result = described_class.implement_stub(file_path: stub_file.path, context: context)
        expect(result[:success]).to be false
        expect(result[:reason]).to eq(:llm_empty_response)
      end

      it 'returns empty response failure when LLM returns nil' do
        allow(llm_response).to receive(:content).and_return(nil)
        result = described_class.implement_stub(file_path: stub_file.path, context: context)
        expect(result[:success]).to be false
        expect(result[:reason]).to eq(:llm_empty_response)
      end
    end

    context 'when file read fails' do
      before do
        stub_const('Legion::LLM', Module.new do
          def self.chat(**) = nil
          def self.respond_to?(mth, *) = mth == :chat ? true : super
        end)
        allow(described_class).to receive(:allowed_stub_path?).and_return(true)
      end

      it 'returns generation_error' do
        result = described_class.implement_stub(file_path: '/nonexistent/path.rb', context: context)
        expect(result[:success]).to be false
        expect(result[:reason]).to eq(:generation_error)
      end
    end
  end

  describe '.generate_full_extension' do
    let(:gap) { { id: 'gap_002', intent: 'manage deployments', occurrence_count: 15 } }

    context 'when Generate runner is available' do
      it 'delegates to scaffold_extension' do
        expect(Legion::Extensions::Codegen::Runners::Generate).to receive(:scaffold_extension).and_return(
          { success: true, path: '/tmp/lex-deploy', files_created: 10 }
        )
        result = described_class.generate_full_extension(gap: gap)
        expect(result[:success]).to be true
      end
    end
  end
end
