# frozen_string_literal: true

require "test_prof/printers/json"

module TestProf::TagProf
  module Printers
    module Json # :nodoc: all
      class << self
        include TestProf::Printers::Json

        def dump(result)
          data = {
            tag: result.tag,
            events: result.events,
            data: result.data.values
          }

          dump_json("tag_prof", data, filename: "tag-prof.json")
        end
      end
    end
  end
end
