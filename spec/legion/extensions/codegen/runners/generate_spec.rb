# frozen_string_literal: true

require 'tmpdir'

RSpec.describe Legion::Extensions::Codegen::Runners::Generate do
  subject(:runner) { described_class }

  let(:tmpdir) { Dir.mktmpdir('lex_codegen_generate_spec') }

  after { FileUtils.rm_rf(tmpdir) }

  describe '.scaffold_extension' do
    it 'responds to scaffold_extension' do
      expect(runner).to respond_to(:scaffold_extension)
    end

    it 'returns a hash with success key' do
      result = runner.scaffold_extension(
        name:        'wonder',
        module_name: 'Wonder',
        description: 'Test extension',
        base_path:   tmpdir
      )
      expect(result).to be_a(Hash)
      expect(result).to have_key(:success)
    end

    it 'returns success: true on valid input' do
      result = runner.scaffold_extension(
        name:        'wonder',
        module_name: 'Wonder',
        description: 'Test extension',
        base_path:   tmpdir
      )
      expect(result[:success]).to be true
    end

    it 'creates the extension directory' do
      runner.scaffold_extension(
        name:        'wonder',
        module_name: 'Wonder',
        description: 'Test extension',
        base_path:   tmpdir
      )
      expect(File.directory?(File.join(tmpdir, 'lex-wonder'))).to be true
    end

    it 'creates a Gemfile' do
      runner.scaffold_extension(
        name:        'wonder',
        module_name: 'Wonder',
        description: 'Test extension',
        base_path:   tmpdir
      )
      expect(File.exist?(File.join(tmpdir, 'lex-wonder', 'Gemfile'))).to be true
    end

    it 'creates a gemspec' do
      runner.scaffold_extension(
        name:        'wonder',
        module_name: 'Wonder',
        description: 'Test extension',
        base_path:   tmpdir
      )
      expect(File.exist?(File.join(tmpdir, 'lex-wonder', 'lex-wonder.gemspec'))).to be true
    end

    it 'creates a version file' do
      runner.scaffold_extension(
        name:        'wonder',
        module_name: 'Wonder',
        description: 'Test extension',
        base_path:   tmpdir
      )
      expect(File.exist?(File.join(tmpdir, 'lex-wonder', 'lib/legion/extensions/wonder/version.rb'))).to be true
    end

    it 'creates a spec_helper' do
      runner.scaffold_extension(
        name:        'wonder',
        module_name: 'Wonder',
        description: 'Test extension',
        base_path:   tmpdir
      )
      expect(File.exist?(File.join(tmpdir, 'lex-wonder', 'spec/spec_helper.rb'))).to be true
    end

    it 'reports files_created count' do
      result = runner.scaffold_extension(
        name:        'wonder',
        module_name: 'Wonder',
        description: 'Test extension',
        base_path:   tmpdir
      )
      expect(result[:files_created]).to be_positive
    end

    it 'generates runner files when runner_methods provided' do
      result = runner.scaffold_extension(
        name:           'wonder',
        module_name:    'Wonder',
        description:    'Test extension',
        base_path:      tmpdir,
        runner_methods: [{ name: 'detect_gaps', params: ['prior_results: {}'], returns: '{}' }]
      )
      expect(result[:success]).to be true
      expect(File.exist?(File.join(tmpdir, 'lex-wonder', 'lib/legion/extensions/wonder/runners/detect_gaps.rb'))).to be true
    end

    it 'generates helper files when helpers provided' do
      result = runner.scaffold_extension(
        name:        'wonder',
        module_name: 'Wonder',
        description: 'Test extension',
        base_path:   tmpdir,
        helpers:     [{ name: 'wonder_store', methods: [] }]
      )
      expect(result[:success]).to be true
      expect(File.exist?(File.join(tmpdir, 'lex-wonder', 'lib/legion/extensions/wonder/helpers/wonder_store.rb'))).to be true
    end
  end

  describe '.generate_file' do
    it 'responds to generate_file' do
      expect(runner).to respond_to(:generate_file)
    end

    it 'returns a hash with success key' do
      output = File.join(tmpdir, 'out.rb')
      result = runner.generate_file(
        template_type: :version,
        variables:     { module_name: 'Test', gem_version: '0.1.0' },
        output_path:   output
      )
      expect(result).to have_key(:success)
    end

    it 'writes the rendered file to disk' do
      output = File.join(tmpdir, 'version.rb')
      runner.generate_file(
        template_type: :version,
        variables:     { module_name: 'Test', gem_version: '0.1.0' },
        output_path:   output
      )
      content = File.read(output)
      expect(content).to include('Test')
      expect(content).to include('0.1.0')
    end

    it 'returns success: false for unknown template type' do
      output = File.join(tmpdir, 'bad.rb')
      result = runner.generate_file(
        template_type: :not_a_real_template,
        variables:     {},
        output_path:   output
      )
      expect(result[:success]).to be false
      expect(result[:error]).to be_a(String)
    end
  end
end
