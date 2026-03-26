# frozen_string_literal: true

module Legion
  module Extensions
    module Codegen
      class Client
        include Runners::Generate
        include Runners::Template
        include Runners::Validate
        include Runners::FromGap
        include Runners::ReviewHandler

        def initialize(base_path: ::Dir.pwd)
          @base_path = base_path
        end
      end
    end
  end
end
