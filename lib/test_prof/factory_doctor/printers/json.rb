# frozen_string_literal: true

require "test_prof/printers/json"

module TestProf
  module FactoryDoctor
    module Printers
      module Json # :nodoc: all
        class << self
          include TestProf::Printers::Json

          def dump(results)
            data = {
              total_bad_examples: results[:total_bad_examples],
              total_wasted_time: results[:total_wasted_time],
              groups: results[:groups]
            }

            dump_json("factory_doctor", data, filename: "factory-doctor.json")
          end
        end
      end
    end
  end
end
