# frozen_string_literal: true

require "test_prof/utils/sized_ordered_set"

module TestProf
  module TPSProf
    class Profiler
      attr_reader :top_count, :groups, :total_count, :total_time, :threshold

      def initialize(top_count, threshold: 10)
        @threshold = threshold
        @top_count = top_count
        @total_count = 0
        @total_time = 0.0
        @groups = Utils::SizedOrderedSet.new(top_count, sort_by: :tps)
      end

      def group_started(id)
        @current_group = id
        @examples_count = 0
        @examples_time = 0.0
        @group_started_at = TestProf.now
      end

      def group_finished(id)
        return unless @examples_count >= threshold

        # Context-time
        group_time = (TestProf.now - @group_started_at) - @examples_time
        run_time = @examples_time + group_time

        groups << {
          id: id,
          run_time: run_time,
          group_time: group_time,
          count: @examples_count,
          tps: -(@examples_count / run_time).round(2)
        }
      end

      def example_started(id)
        @example_started_at = TestProf.now
      end

      def example_finished(id)
        @examples_count += 1
        @total_count += 1

        time = (TestProf.now - @example_started_at)
        @examples_time += time
        @total_time += time
      end
    end
  end
end
