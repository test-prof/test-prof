# frozen_string_literal: true

require "test_prof/event_prof/printers/base"
require "test_prof/ext/float_duration"

module TestProf
  module EventProf
    module Printers
      module Json # :nodoc: all
        class << self
          using TestProf::FloatDuration

          include Base

          def dump(profilers)
            data = []
            profilers.each { |profiler| data << convert_results(profiler) }

            outpath = TestProf.artifact_path("event-prof.json")
            File.write(outpath, data.to_json)

            log :info, "EventProf results to JSON: #{outpath}"
          end

          private

          def convert_results(profiler)
            result = profiler.results

            {
              event: profiler.event,
              total_time: profiler.total_time.duration,
              total_count: profiler.total_count,
              absolute_run_time: profiler.absolute_run_time.duration,
              time_percentage: time_percentage(profiler.total_time, profiler.absolute_run_time),
              rank_by: profiler.rank_by,
              top_count: profiler.top_count,
              groups: result[:groups].map { |group| convert_group(group) }
            }.tap do |data|
              next unless result[:examples]

              data[:examples] = result[:examples].map { |example| convert_example(example) }
            end
          end

          def convert_group(group)
            {
              description: describe_group(group[:id]),
              location: locate(group[:id]),
              time: group[:time].duration,
              run_time: group[:run_time].duration,
              time_percentage: time_percentage(group[:time], group[:run_time]),
              count: group[:count],
              examples: group[:examples]
            }
          end

          def convert_example(example)
            {
              description: describe_example(example[:id]),
              location: locate(example[:id]),
              time: example[:time].duration,
              run_time: example[:run_time].duration,
              time_percentage: time_percentage(example[:time], example[:run_time]),
              count: example[:count]
            }
          end
        end
      end
    end
  end
end
