# frozen_string_literal: true

require "test_prof/ext/float_duration"
require "test_prof/ext/string_truncate"

module TestProf
  module TPSProf
    module Reporter
      class Text
        include Logging
        using FloatDuration
        using StringTruncate

        def print(profiler)
          groups = profiler.groups

          total_tps = (profiler.total_count / profiler.total_time).round(2)

          msgs = []

          msgs <<
            <<~MSG
              Total TPS (tests per second): #{total_tps}

              Top #{profiler.top_count} slowest suites by TPS (tests per second) (min examples per group: #{profiler.threshold}):

            MSG

          groups.each do |group|
            description = group[:id].top_level_description
            location = group[:id].metadata[:location]
            time = group[:run_time]
            group_time = group[:group_time]
            count = group[:count]
            tps = -group[:tps]

            msgs <<
              <<~GROUP
                #{description.truncate} (#{location}) – #{tps} TPS (#{time.duration} / #{count}), group time: #{group_time.duration}
              GROUP
          end

          log :info, msgs.join
        end
      end
    end
  end
end
