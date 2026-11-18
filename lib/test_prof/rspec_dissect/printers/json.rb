# frozen_string_literal: true

require "test_prof/printers/json"

module TestProf
  module RSpecDissect
    module Printers
      module Json # :nodoc: all
        class << self
          include TestProf::Printers::Json

          def dump(results)
            data = {
              top_count: results[:top_count],
              total_time: results[:total_time],
              total_setup_time: results[:total_setup_time],
              groups: results[:groups]
            }

            dump_json("rspec_dissect", data, filename: "rspec-dissect.json")
          end
        end
      end
    end
  end
end
