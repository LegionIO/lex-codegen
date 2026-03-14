# frozen_string_literal: true

RSpec.describe Legion::Extensions::Codegen::Helpers::SpecGenerator do
  subject(:gen) { described_class.new }

  let(:module_name)   { 'Wonder' }
  let(:runner_name)   { 'detect_gaps' }
  let(:methods) do
    [
      { name: 'detect_gaps',  params: ['prior_results: {}'] },
      { name: 'list_gaps',    params: [] }
    ]
  end

  describe '#generate_runner_spec' do
    it 'returns a string' do
      result = gen.generate_runner_spec(module_name: module_name, runner_name: runner_name, methods: methods)
      expect(result).to be_a(String)
    end

    it 'includes frozen_string_literal comment' do
      result = gen.generate_runner_spec(module_name: module_name, runner_name: runner_name, methods: methods)
      expect(result).to start_with('# frozen_string_literal: true')
    end

    it 'includes RSpec.describe for the runner module' do
      result = gen.generate_runner_spec(module_name: module_name, runner_name: runner_name, methods: methods)
      expect(result).to include('Legion::Extensions::Wonder::Runners::DetectGaps')
    end

    it 'includes respond_to checks for each method' do
      result = gen.generate_runner_spec(module_name: module_name, runner_name: runner_name, methods: methods)
      expect(result).to include('respond_to(:detect_gaps)')
      expect(result).to include('respond_to(:list_gaps)')
    end

    it 'includes success key expectation for each method' do
      result = gen.generate_runner_spec(module_name: module_name, runner_name: runner_name, methods: methods)
      expect(result).to include('have_key(:success)')
    end

    it 'works with empty methods array' do
      result = gen.generate_runner_spec(module_name: module_name, runner_name: runner_name, methods: [])
      expect(result).to be_a(String)
      expect(result).to include('RSpec.describe')
    end
  end

  describe '#generate_client_spec' do
    it 'returns a string' do
      result = gen.generate_client_spec(module_name: module_name, runner_name: runner_name, methods: methods)
      expect(result).to be_a(String)
    end

    it 'includes instantiation test' do
      result = gen.generate_client_spec(module_name: module_name, runner_name: runner_name, methods: methods)
      expect(result).to include('instantiates successfully')
    end

    it 'includes respond_to checks for each method' do
      result = gen.generate_client_spec(module_name: module_name, runner_name: runner_name, methods: methods)
      expect(result).to include('respond_to(:detect_gaps)')
    end
  end

  describe '#generate_helper_spec' do
    it 'returns a string' do
      result = gen.generate_helper_spec(module_name: module_name, helper_name: 'wonder_store', methods: [])
      expect(result).to be_a(String)
    end

    it 'includes describe block for the helper class' do
      result = gen.generate_helper_spec(module_name: module_name, helper_name: 'wonder_store', methods: [])
      expect(result).to include('Legion::Extensions::Wonder::Helpers::WonderStore')
    end

    it 'includes instantiation test' do
      result = gen.generate_helper_spec(module_name: module_name, helper_name: 'wonder_store', methods: [])
      expect(result).to include('instantiates successfully')
    end
  end
end
