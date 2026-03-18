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

            MSG

          if profiler.mode == :strict
            return if groups.empty?

            msgs << if groups.size < profiler.top_count
              <<~MSG
                Suites violating TPS limits:

              MSG
            else
              <<~MSG
                Top #{profiler.top_count} suites violating TPS limits:

              MSG
            end
          else
            msgs <<
              <<~MSG
                Top #{profiler.top_count} slowest suites by TPS (tests per second):

              MSG
          end

          groups.each do |group|
            description = group[:id].top_level_description
            location = group[:id].metadata[:location]
            time = group[:total_time]
            setup_time = group[:shared_setup_time]
            count = group[:count]
            tps = group[:tps]

            msgs <<
              <<~GROUP
                #{description.truncate} (#{location}) – #{tps} TPS (#{time.duration} / #{count}, shared setup time: #{setup_time.duration})
              GROUP
          end

          log((profiler.mode == :strict) ? :error : :info, msgs.join)
        end
      end
    end
  end
end
