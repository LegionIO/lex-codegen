# frozen_string_literal: true

RSpec.describe Legion::Extensions::Codegen::Runners::Template do
  subject(:runner) { described_class }

  describe '.list_templates' do
    it 'responds to list_templates' do
      expect(runner).to respond_to(:list_templates)
    end

    it 'returns a hash with success: true' do
      result = runner.list_templates
      expect(result[:success]).to be true
    end

    it 'returns a templates array' do
      result = runner.list_templates
      expect(result[:templates]).to be_an(Array)
      expect(result[:templates]).not_to be_empty
    end

    it 'includes all expected template types' do
      result = runner.list_templates
      expect(result[:templates]).to include(:gemspec, :gemfile, :rubocop, :version, :runner, :client)
    end
  end

  describe '.render_template' do
    it 'responds to render_template' do
      expect(runner).to respond_to(:render_template)
    end

    it 'renders a known template' do
      result = runner.render_template(template_type: :gemfile)
      expect(result[:success]).to be true
      expect(result[:content]).to be_a(String)
    end

    it 'returns the template_type in the result' do
      result = runner.render_template(template_type: :gemfile)
      expect(result[:template_type]).to eq(:gemfile)
    end

    it 'renders with variables substituted' do
      result = runner.render_template(
        template_type: :version,
        variables:     { module_name: 'Fancy', gem_version: '2.0.0' }
      )
      expect(result[:content]).to include('Fancy')
      expect(result[:content]).to include('2.0.0')
    end

    it 'returns success: false for unknown template type' do
      result = runner.render_template(template_type: :bogus_type)
      expect(result[:success]).to be false
      expect(result[:error]).to be_a(String)
    end
  end

  describe '.template_variables' do
    it 'responds to template_variables' do
      expect(runner).to respond_to(:template_variables)
    end

    it 'returns required variables for a template type' do
      result = runner.template_variables(template_type: :version)
      expect(result[:success]).to be true
      expect(result[:required_variables]).to be_an(Array)
    end

    it 'returns success: false for unknown template type' do
      result = runner.template_variables(template_type: :nonexistent)
      expect(result[:success]).to be false
    end

    it 'returns the template_type in the result' do
      result = runner.template_variables(template_type: :gemfile)
      expect(result[:template_type]).to eq(:gemfile)
    end
  end
end
