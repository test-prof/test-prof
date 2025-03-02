# frozen_string_literal: true

module TestProf::FactoryProf
  module Printers
    class SimpleTruncated < Simple # :nodoc: all
      class << self
        private

        def format_string(indent, name)
          "%-#{indent}s%-#{name}.#{name}s %8d %11d %13.4fs %17.4fs %18.4fs"
        end
      end
    end
  end
end
