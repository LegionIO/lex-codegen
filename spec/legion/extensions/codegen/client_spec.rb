# frozen_string_literal: true

RSpec.describe Legion::Extensions::Codegen::Client do
  subject(:client) { described_class.new }

  describe '#initialize' do
    it 'instantiates successfully' do
      expect(client).to be_a(described_class)
    end

    it 'accepts a custom base_path' do
      custom = described_class.new(base_path: '/tmp')
      expect(custom).to be_a(described_class)
    end
  end

  describe 'runner delegation' do
    it 'responds to scaffold_extension' do
      expect(client).to respond_to(:scaffold_extension)
    end

    it 'responds to generate_file' do
      expect(client).to respond_to(:generate_file)
    end

    it 'responds to list_templates' do
      expect(client).to respond_to(:list_templates)
    end

    it 'responds to render_template' do
      expect(client).to respond_to(:render_template)
    end

    it 'responds to template_variables' do
      expect(client).to respond_to(:template_variables)
    end

    it 'responds to validate_structure' do
      expect(client).to respond_to(:validate_structure)
    end

    it 'responds to validate_rubocop_config' do
      expect(client).to respond_to(:validate_rubocop_config)
    end

    it 'responds to validate_gemspec' do
      expect(client).to respond_to(:validate_gemspec)
    end
  end

  describe '#list_templates' do
    it 'returns a hash with success: true' do
      result = client.list_templates
      expect(result[:success]).to be true
    end

    it 'returns the templates array' do
      result = client.list_templates
      expect(result[:templates]).to be_an(Array)
    end
  end

  describe '#render_template' do
    it 'renders a template successfully' do
      result = client.render_template(template_type: :gemfile)
      expect(result[:success]).to be true
      expect(result[:content]).to be_a(String)
    end
  end
end
