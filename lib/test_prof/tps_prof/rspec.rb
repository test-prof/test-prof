# frozen_string_literal: true

module TestProf
  module TPSProf
    class RSpecListener # :nodoc:
      include Logging

      NOTIFICATIONS = %i[
        example_group_started
        example_group_finished
        example_started
        example_finished
      ].freeze

      attr_reader :reporter, :profiler

      def initialize
        @profiler = Profiler.new(TPSProf.config.top_count, threshold: TPSProf.config.threshold)
        @reporter = TPSProf.config.reporter

        log :info, "TPSProf enabled (top-#{TPSProf.config.top_count})"
      end

      def example_group_started(notification)
        return unless notification.group.top_level?
        profiler.group_started notification.group
      end

      def example_group_finished(notification)
        return unless notification.group.top_level?
        profiler.group_finished notification.group
      end

      def example_started(notification)
        profiler.example_started notification.example
      end

      def example_finished(notification)
        profiler.example_finished notification.example
      end

      def print
        reporter.print(profiler)
      end
    end
  end
end

# Register TPSProf listener
TestProf.activate("TPS_PROF") do
  RSpec.configure do |config|
    listener = nil

    config.before(:suite) do
      listener = TestProf::TPSProf::RSpecListener.new
      config.reporter.register_listener(
        listener, *TestProf::TPSProf::RSpecListener::NOTIFICATIONS
      )
    end

    config.after(:suite) { listener&.print }
  end
end
