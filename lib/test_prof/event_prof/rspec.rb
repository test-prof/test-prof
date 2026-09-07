# frozen_string_literal: true

module TestProf
  module EventProf
    class RSpecListener # :nodoc:
      include Logging

      NOTIFICATIONS = %i[
        example_group_started
        example_group_finished
        example_started
        example_finished
      ].freeze

      def initialize
        @profiler = EventProf.build

        log :info, "EventProf enabled (#{@profiler.events.join(", ")})"
      end

      def example_group_started(notification)
        return unless notification.group.top_level?
        @profiler.group_started notification.group
      end

      def example_group_finished(notification)
        return unless notification.group.top_level?
        @profiler.group_finished notification.group
      end

      def example_started(notification)
        @profiler.example_started notification.example
      end

      def example_finished(notification)
        @profiler.example_finished notification.example
      end

      def print
        EventProf.config.printer.dump(@profiler)

        return unless EventProf.config.stamp?

        @profiler.each { |profiler| stamp!(profiler) }
      end

      def stamp!(profiler)
        result = profiler.results

        stamper = RSpecStamp::Stamper.new

        examples = Hash.new { |h, k| h[k] = [] }

        (result[:groups].to_a + result.fetch(:examples, []).to_a)
          .map { |obj| obj[:id].metadata[:location] }.each do |location|
          file, line = location.split(":")
          examples[file] << line.to_i
        end

        examples.each do |file, lines|
          stamper.stamp_file(file, lines.uniq)
        end

        msgs = []

        msgs <<
          <<~MSG
            RSpec Stamp results

            Total patches: #{stamper.total}
            Total files: #{examples.keys.size}

            Failed patches: #{stamper.failed}
            Ignored files: #{stamper.ignored}
          MSG

        log :info, msgs.join
      end
    end
  end
end

# Register EventProf listener
TestProf.activate("EVENT_PROF") do
  TestProf::EventProf::CustomEvents.activate_all(ENV["EVENT_PROF"])

  RSpec.configure do |config|
    listener = nil

    config.before(:suite) do
      listener = TestProf::EventProf::RSpecListener.new
      config.reporter.register_listener(
        listener, *TestProf::EventProf::RSpecListener::NOTIFICATIONS
      )
    end

    config.after(:suite) { listener&.print }
  end
end
