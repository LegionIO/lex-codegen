# frozen_string_literal: true

RSpec.describe Legion::Extensions::Codegen::Helpers::TemplateEngine do
  subject(:engine) { described_class.new }

  describe '#render' do
    it 'renders a known template type' do
      result = engine.render(:gemfile)
      expect(result).to be_a(String)
      expect(result).to include('rubygems.org')
    end

    it 'renders version template with variables' do
      result = engine.render(:version, module_name: 'TestExt', gem_version: '1.2.3')
      expect(result).to include('TestExt')
      expect(result).to include('1.2.3')
    end

    it 'renders rubocop template with ruby version' do
      result = engine.render(:rubocop, ruby_version: '3.4')
      expect(result).to include('3.4')
      expect(result).to include('LineLength')
    end

    it 'raises ArgumentError for unknown template type' do
      expect { engine.render(:nonexistent_template) }.to raise_error(ArgumentError, /Unknown template type/)
    end

    it 'renders license template with author substituted' do
      result = engine.render(:license, author: 'TestAuthor')
      expect(result).to include('TestAuthor')
    end
  end

  describe '#render_string' do
    it 'renders arbitrary ERB string with variables' do
      result = engine.render_string('Hello <%= name %>!', name: 'Legion')
      expect(result).to eq('Hello Legion!')
    end

    it 'handles templates with no variables' do
      result = engine.render_string('plain text')
      expect(result).to eq('plain text')
    end

    it 'handles trim mode for cleaner output' do
      template = "line one\n<% if false -%>\nskipped\n<% end -%>\nline two"
      result = engine.render_string(template)
      expect(result).to include('line one')
      expect(result).to include('line two')
      expect(result).not_to include('skipped')
    end

    it 'renders arrays via iteration' do
      template = "<% items.each do |i| -%>\n<%= i %>\n<% end -%>"
      result = engine.render_string(template, items: %w[alpha beta gamma])
      expect(result).to include('alpha')
      expect(result).to include('beta')
      expect(result).to include('gamma')
    end
  end
end
