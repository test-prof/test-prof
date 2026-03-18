# frozen_string_literal: true

require "test_prof/utils/sized_ordered_set"
require "forwardable"

module TestProf
  module TPSProf
    class Profiler
      extend Forwardable

      attr_reader :top_count, :groups, :total_count, :total_time,
        :config

      def_delegators :@config, :min_examples_count, :min_group_time, :min_target_tps,
        :mode, :max_examples_count, :max_group_time, :min_tps

      def initialize(top_count, config)
        @config = config
        # In strict mode, we use the sorted set to keep track of offenders
        # to show in the end
        @top_count = (config.mode == :strict) ? 100 : top_count
        @total_count = 0
        @total_time = 0.0
        @groups = Utils::SizedOrderedSet.new(top_count, sort_by: :penalty)
      end

      def group_started(id)
        @current_group = id
        @examples_count = 0
        @examples_time = 0.0
        @group_started_at = TestProf.now
      end

      def group_finished(group)
        return unless @examples_count >= min_examples_count

        total_time = TestProf.now - @group_started_at
        shared_setup_time = total_time - @examples_time

        return unless total_time >= min_group_time

        tps = (@examples_count / total_time).round(2)

        return unless tps < min_target_tps

        # How much time did we waste compared to the target TPS
        penalty = @examples_count * ((1.0 / tps) - (1.0 / min_target_tps))

        item = {
          id: group,
          total_time: total_time,
          shared_setup_time: shared_setup_time,
          count: @examples_count,
          tps: tps,
          penalty: penalty
        }

        if mode == :strict
          location = group.metadata[:location]

          if TPSProf.handle_group_strictly(
            GroupInfo.new(
              group: group,
              location: location,
              examples_count: @examples_count,
              total_time: total_time,
              tps: tps,
              penalty: penalty
            )
          )
            groups << item
          end
        else
          groups << item
        end
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
