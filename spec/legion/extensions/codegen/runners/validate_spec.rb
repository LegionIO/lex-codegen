# frozen_string_literal: true

require 'tmpdir'

RSpec.describe Legion::Extensions::Codegen::Runners::Validate do
  subject(:runner) { described_class }

  let(:tmpdir) { Dir.mktmpdir('lex_codegen_validate_spec') }

  after { FileUtils.rm_rf(tmpdir) }

  describe '.validate_structure' do
    it 'responds to validate_structure' do
      expect(runner).to respond_to(:validate_structure)
    end

    it 'returns a hash with valid key' do
      result = runner.validate_structure(path: tmpdir)
      expect(result).to have_key(:valid)
    end

    it 'returns valid: false for empty directory' do
      result = runner.validate_structure(path: tmpdir)
      expect(result[:valid]).to be false
    end

    it 'returns missing files list' do
      result = runner.validate_structure(path: tmpdir)
      expect(result[:missing]).to be_an(Array)
      expect(result[:missing]).not_to be_empty
    end

    it 'returns valid: true when all required files exist' do
      File.write(File.join(tmpdir, 'Gemfile'), '# gemfile')
      File.write(File.join(tmpdir, 'lex-test.gemspec'), '# gemspec')
      File.write(File.join(tmpdir, '.rubocop.yml'), '# rubocop')
      FileUtils.mkdir_p(File.join(tmpdir, 'spec'))
      File.write(File.join(tmpdir, 'spec/spec_helper.rb'), '# spec_helper')
      FileUtils.mkdir_p(File.join(tmpdir, 'lib/legion/extensions'))
      File.write(File.join(tmpdir, 'lib/legion/extensions/test.rb'), '# entry')
      FileUtils.mkdir_p(File.join(tmpdir, 'lib/legion/extensions/test'))
      File.write(File.join(tmpdir, 'lib/legion/extensions/test/version.rb'), '# version')

      result = runner.validate_structure(path: tmpdir)
      expect(result[:valid]).to be true
    end

    it 'includes present files in response' do
      File.write(File.join(tmpdir, 'Gemfile'), '# gemfile')
      result = runner.validate_structure(path: tmpdir)
      expect(result[:present]).to include('Gemfile')
    end
  end

  describe '.validate_rubocop_config' do
    it 'responds to validate_rubocop_config' do
      expect(runner).to respond_to(:validate_rubocop_config)
    end

    it 'returns valid: false when .rubocop.yml is missing' do
      result = runner.validate_rubocop_config(path: tmpdir)
      expect(result[:valid]).to be false
      expect(result[:issues]).to include('.rubocop.yml not found')
    end

    it 'returns valid: true for a complete rubocop config' do
      rubocop_content = <<~YAML
        AllCops:
          TargetRubyVersion: 3.4
          NewCops: enable
        Layout/LineLength:
          Max: 160
        Metrics/MethodLength:
          Max: 50
        Style/FrozenStringLiteralComment:
          Enabled: true
      YAML
      File.write(File.join(tmpdir, '.rubocop.yml'), rubocop_content)
      result = runner.validate_rubocop_config(path: tmpdir)
      expect(result[:valid]).to be true
      expect(result[:issues]).to be_empty
    end

    it 'reports missing rubocop keys' do
      File.write(File.join(tmpdir, '.rubocop.yml'), "AllCops:\n  TargetRubyVersion: 3.4\n")
      result = runner.validate_rubocop_config(path: tmpdir)
      expect(result[:issues]).not_to be_empty
    end
  end

  describe '.validate_gemspec' do
    it 'responds to validate_gemspec' do
      expect(runner).to respond_to(:validate_gemspec)
    end

    it 'returns valid: false when no gemspec exists' do
      result = runner.validate_gemspec(path: tmpdir)
      expect(result[:valid]).to be false
    end

    it 'returns valid: true for a complete gemspec' do
      gemspec = <<~RUBY
        Gem::Specification.new do |spec|
          spec.name     = 'lex-test'
          spec.version  = '0.1.0'
          spec.authors  = ['Esity']
          spec.email    = ['matthewdiverson@gmail.com']
          spec.summary  = 'Test'
          spec.description = 'A test gem'
          spec.homepage = 'https://example.com'
          spec.license  = 'MIT'
          spec.metadata['rubygems_mfa_required'] = 'true'
          spec.required_ruby_version = '>= 3.4'
        end
      RUBY
      File.write(File.join(tmpdir, 'lex-test.gemspec'), gemspec)
      result = runner.validate_gemspec(path: tmpdir)
      expect(result[:valid]).to be true
    end

    it 'reports missing gemspec fields' do
      File.write(File.join(tmpdir, 'lex-test.gemspec'), "Gem::Specification.new do |s|\n  s.name = 'test'\nend\n")
      result = runner.validate_gemspec(path: tmpdir)
      expect(result[:valid]).to be false
      expect(result[:issues]).not_to be_empty
    end
  end
end
