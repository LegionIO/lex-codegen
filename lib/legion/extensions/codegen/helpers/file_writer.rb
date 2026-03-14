# frozen_string_literal: true

require 'fileutils'

module Legion
  module Extensions
    module Codegen
      module Helpers
        class FileWriter
          def initialize(base_path:)
            @base_path = base_path
          end

          def write(relative_path, content)
            full_path = ::File.join(@base_path, relative_path)
            ::FileUtils.mkdir_p(::File.dirname(full_path))
            ::File.write(full_path, content)
            { path: full_path, bytes: content.bytesize }
          end

          def write_all(files)
            files.map { |path, content| write(path, content) }
          end
        end
      end
    end
  end
end
