# frozen_string_literal: true

require 'tmpdir'

RSpec.describe Legion::Extensions::Codegen::Helpers::FileWriter do
  subject(:writer) { described_class.new(base_path: tmpdir) }

  let(:tmpdir) { Dir.mktmpdir('lex_codegen_spec') }

  after { FileUtils.rm_rf(tmpdir) }

  describe '#write' do
    it 'writes content to a file and returns metadata' do
      result = writer.write('test.rb', '# hello')
      expect(result[:path]).to end_with('test.rb')
      expect(result[:bytes]).to eq(7)
    end

    it 'creates intermediate directories' do
      writer.write('lib/legion/extensions/foo.rb', '# content')
      expect(File.exist?(File.join(tmpdir, 'lib/legion/extensions/foo.rb'))).to be true
    end

    it 'creates the file with the correct content' do
      writer.write('output.txt', 'hello world')
      expect(File.read(File.join(tmpdir, 'output.txt'))).to eq('hello world')
    end

    it 'returns bytes matching content bytesize' do
      content = 'unicode: äöü'
      result = writer.write('unicode.txt', content)
      expect(result[:bytes]).to eq(content.bytesize)
    end
  end

  describe '#write_all' do
    it 'writes multiple files and returns array of metadata' do
      files = {
        'a.rb'     => '# a',
        'b/c/d.rb' => '# d'
      }
      results = writer.write_all(files)
      expect(results).to be_an(Array)
      expect(results.size).to eq(2)
      expect(results.map { |r| r[:bytes] }).to all(be_positive)
    end

    it 'creates all specified files on disk' do
      files = { 'x.rb' => '# x', 'y.rb' => '# y' }
      writer.write_all(files)
      expect(File.exist?(File.join(tmpdir, 'x.rb'))).to be true
      expect(File.exist?(File.join(tmpdir, 'y.rb'))).to be true
    end
  end
end
