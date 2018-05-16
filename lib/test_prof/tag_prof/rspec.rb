# frozen_string_literal: true

module TestProf
  module TagProf
    class RSpecListener # :nodoc:
      include Logging

      NOTIFICATIONS = %i[
        example_started
        example_failed
        example_passed
      ].freeze

      attr_reader :result, :printer

      def initialize
        @printer = ENV['TAG_PROF_FORMAT'] == 'html' ? Printers::HTML : Printers::Simple

        @result =
          if ENV['TAG_PROF_EVENT'].nil?
            Result.new ENV['TAG_PROF'].to_sym
          else
            require "test_prof/event_prof"

            @events_profiler = EventProf.build(ENV['TAG_PROF_EVENT'])

            Result.new ENV['TAG_PROF'].to_sym, @events_profiler.events
          end

        log :info, "TagProf enabled (#{result.tag})"
      end

      def example_started(_notification)
        @ts = TestProf.now
        # enable event profiling
        @events_profiler.group_started(true) if @events_profiler
      end

      def example_finished(notification)
        tag = notification.example.metadata.fetch(result.tag, :__unknown__)

        result.track(tag, time: TestProf.now - @ts, events: fetch_events_data)

        # reset and disable event profilers
        @events_profiler.group_started(nil) if @events_profiler
      end

      # NOTE: RSpec < 3.4.0 doesn't have example_finished event
      alias example_passed example_finished
      alias example_failed example_finished

      def report
        printer.dump(result)
      end

      private

      def fetch_events_data
        return {} unless @events_profiler

        Hash[
          @events_profiler.profilers.map do |profiler|
            [profiler.event, profiler.time]
          end
        ]
      end
    end
  end
end

# Register TagProf listener
TestProf.activate('TAG_PROF') do
  RSpec.configure do |config|
    listener = nil

    config.before(:suite) do
      listener = TestProf::TagProf::RSpecListener.new
      config.reporter.register_listener(
        listener, *TestProf::TagProf::RSpecListener::NOTIFICATIONS
      )
    end

    config.after(:suite) { listener.report unless listener.nil? }
  end
end
