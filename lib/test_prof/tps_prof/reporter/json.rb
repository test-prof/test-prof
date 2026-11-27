# frozen_string_literal: true

require "test_prof/printers/json"

module TestProf
  module TPSProf
    module Reporter
      class Json # :nodoc: all
        include TestProf::Printers::Json

        def print(profiler)
          data = {
            mode: profiler.mode,
            top_count: profiler.top_count,
            total_count: profiler.total_count,
            total_time: profiler.total_time,
            total_tps: total_tps(profiler),
            groups: profiler.groups.map { |group| convert(group) }
          }

          dump_json("tps_prof", data, filename: "tps-prof.json")
        end

        private

        def total_tps(profiler)
          return 0.0 if profiler.total_time.zero?

          (profiler.total_count / profiler.total_time).round(2)
        end

        def convert(group)
          {
            description: group[:id].top_level_description,
            location: group[:id].metadata[:location],
            total_time: group[:total_time],
            shared_setup_time: group[:shared_setup_time],
            count: group[:count],
            tps: group[:tps],
            penalty: group[:penalty]
          }
        end
      end
    end
  end
end
