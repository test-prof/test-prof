# frozen_string_literal: true

require "test_prof/ext/float_duration"
require "test_prof/ext/string_truncate"

module Minitest
  module TestProf
    class EventProfFormatter # :nodoc:
      using ::TestProf::FloatDuration
      using ::TestProf::StringTruncate

      def initialize(profilers)
        @profilers = profilers
        @results = []
      end

      def prepare_results
        @profilers.each do |profiler|
          total_results(profiler)
          by_groups(profiler)
          by_examples(profiler)
        end
        @results.join
      end

      private

      def total_results(profiler)
        @results <<
          <<~MSG
            EventProf results for #{profiler.event}

            Total time: #{profiler.total_time.duration}
            Total events: #{profiler.total_count}

            Top #{profiler.top_count} slowest suites (by #{profiler.rank_by}):

          MSG
      end

      def by_groups(profiler)
        profiler.results[:groups].each do |group|
          description = group[:id][:name]
          location = group[:id][:location]

          @results <<
            <<~GROUP
              #{description.truncate} (#{location}) – #{group[:time].duration} (#{group[:count]} / #{group[:examples]})
            GROUP
        end
      end

      def by_examples(profiler)
        return unless profiler.results[:examples]
        @results << "\nTop #{profiler.top_count} slowest tests (by #{profiler.rank_by}):\n\n"

        profiler.results[:examples].each do |example|
          description = example[:id][:name]
          location = example[:id][:location]

          @results <<
            <<~GROUP
              #{description.truncate} (#{location}) – #{example[:time].duration} (#{example[:count]})
            GROUP
        end
      end
    end
  end
end
