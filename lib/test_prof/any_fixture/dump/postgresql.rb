# frozen_string_literal: true

module TestProf
  module AnyFixture
    class Dump
      module PostgreSQL
        module_function

        def reset_sequence!(table_name, start)
        end

        def import(path)
          false
        end
      end
    end
  end
end
