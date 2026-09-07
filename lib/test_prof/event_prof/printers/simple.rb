# frozen_string_literal: true

require "test_prof/event_prof/printers/base"
require "test_prof/ext/float_duration"
require "test_prof/ext/string_truncate"

module TestProf
  module EventProf
    module Printers
      module Simple # :nodoc: all
        class << self
          using TestProf::FloatDuration
          using TestProf::StringTruncate

          include Base

          def dump(profilers)
            profilers.each { |profiler| dump_profiler(profiler) }
          end

          private

          def dump_profiler(profiler)
            result = profiler.results
            time_percentage = time_percentage(profiler.total_time, profiler.absolute_run_time)

            msgs = []

            msgs <<
              <<~MSG
                EventProf results for #{profiler.event}

                Total time: #{profiler.total_time.duration} of #{profiler.absolute_run_time.duration} (#{time_percentage}%)
                Total events: #{profiler.total_count}

                Top #{profiler.top_count} slowest suites (by #{profiler.rank_by}):

              MSG

            result[:groups].each do |group|
              description = describe_group(group[:id])
              location = locate(group[:id])
              time = group[:time]
              run_time = group[:run_time]
              time_percentage = time_percentage(time, run_time)

              msgs <<
                <<~GROUP
                  #{description.truncate} (#{location}) – #{time.duration} (#{group[:count]} / #{group[:examples]}) of #{run_time.duration} (#{time_percentage}%)
                GROUP
            end

            if result[:examples]
              msgs << "\nTop #{profiler.top_count} slowest tests (by #{profiler.rank_by}):\n\n"

              result[:examples].each do |example|
                description = describe_example(example[:id])
                location = locate(example[:id])
                time = example[:time]
                run_time = example[:run_time]
                time_percentage = time_percentage(time, run_time)

                msgs <<
                  <<~GROUP
                    #{description.truncate} (#{location}) – #{time.duration} (#{example[:count]}) of #{run_time.duration} (#{time_percentage}%)
                  GROUP
              end
            end

            log :info, msgs.join
          end
        end
      end
    end
  end
end
