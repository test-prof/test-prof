# frozen_string_literal: true

require "test_prof/event_prof/instrumentations/active_support"

module TestProf
  # EventProf profiles your tests and suites against custom events,
  # such as ActiveSupport::Notifacations.
  #
  # It works very similar to `rspec --profile` but can track arbitrary events.
  #
  # Example:
  #
  #   # Collect SQL queries stats for every suite and example
  #   EVENT_PROF='sql.active_record' rspec ...
  #
  # By default it collects information only about top-level groups (aka suites),
  # but you can also profile individual examples. Just set the configuration option:
  #
  #  TestProf::EventProf.configure do |config|
  #    config.per_example = true
  #  end
  module EventProf
    # EventProf configuration
    class Configuration
      # Map of supported instrumenters
      INSTRUMENTERS = {
        active_support: 'ActiveSupport'
      }.freeze

      attr_accessor :instrumenter, :top_count, :per_example,
                    :rank_by, :event

      def initialize
        @event = ENV['EVENT_PROF']
        @instrumenter = :active_support
        @top_count = (ENV['EVENT_PROF_TOP'] || 5).to_i
        @per_example = false
        @rank_by = (ENV['EVENT_PROF_RANK'] || :time).to_sym
      end

      def per_example?
        per_example == true
      end

      def resolve_instrumenter
        return instrumenter if instrumenter.is_a?(Module)

        raise ArgumentError, "Unknown instrumenter: #{instrumenter}" unless
          INSTRUMENTERS.key?(instrumenter)

        Instrumentations.const_get(INSTRUMENTERS[instrumenter])
      end
    end

    class << self
      def config
        @config ||= Configuration.new
      end

      def configure
        yield config
      end

      # Returns new configured instance of profiler
      def build
        Profiler.new(
          event: config.event,
          instrumenter: config.resolve_instrumenter
        )
      end
    end

    class Profiler # :nodoc:
      include TestProf::Logging

      attr_reader :event, :top_count, :rank_by, :total_count, :total_time

      def initialize(event:, instrumenter:)
        @event = event

        log :info, "EventProf enabled (#{@event})"

        instrumenter.subscribe(event) { |time| track(time) }

        @groups = Hash.new { |h, k| h[k] = { id: k } }
        @examples = Hash.new { |h, k| h[k] = { id: k } }

        @total_count = 0
        @total_time = 0.0

        reset!
      end

      def track(time)
        return if @current_group.nil?
        @total_time += time
        @total_count += 1

        @time += time
        @count += 1

        @example_time += time if config.per_example?
        @example_count += 1 if config.per_example?
      end

      def group_started(id)
        reset!
        @current_group = id
      end

      def group_finished(id)
        @groups[id][:time] = @time
        @groups[id][:count] = @count
        @groups[id][:examples] = @total_examples
        @current_group = nil
      end

      def example_started(_id)
        reset_example!
      end

      def example_finished(id)
        @total_examples += 1
        return unless config.per_example?

        @examples[id][:time] = @example_time
        @examples[id][:count] = @example_count
      end

      def results
        {
          groups: fetch_top(@groups.values)
        }.tap do |data|
          next unless config.per_example?

          data[:examples] = fetch_top(@examples.values)
        end
      end

      def rank_by
        EventProf.config.rank_by
      end

      def top_count
        EventProf.config.top_count
      end

      private

      def fetch_top(arr)
        arr.reject { |el| el[rank_by].zero? }
           .sort_by { |el| -el[rank_by] }
           .take(top_count)
      end

      def config
        EventProf.config
      end

      def reset!
        @time = 0.0
        @count = 0
        @total_examples = 0
        reset_example!
      end

      def reset_example!
        @example_count = 0
        @example_time = 0.0
      end
    end
  end
end

require "test_prof/event_prof/rspec" if defined?(RSpec::Core)
require "test_prof/event_prof/minitest" if defined?(Minitest::Reporters)
require "test_prof/event_prof/custom_events"
