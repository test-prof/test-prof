# frozen_string_literal: true

require "test_prof/ext/float_duration"

module TestProf
  module TagProf
    class RSpecListener # :nodoc:
      include Logging
      using FloatDuration

      NOTIFICATIONS = %i[
        example_started
        example_finished
      ].freeze

      def initialize
        @tag = ENV['TAG_PROF'].to_sym
        @tags = Hash.new { |h, k| h[k] = { val: k, count: 0, time: 0.0 } }

        log :info, "TagProf enabled (#{@tag})"
      end

      def example_started(_notification)
        @ts = Time.now
      end

      def example_finished(notification)
        return if notification.example.pending?

        tag = notification.example.metadata.fetch(@tag, :__unknown__)

        @tags[tag][:count] += 1
        @tags[tag][:time] += (Time.now - @ts)
      end

      def print
        msgs = []

        msgs <<
          <<~MSG
            TagProf report for #{@tag}
          MSG

        msgs << format(
          "%15s  %12s  %6s  %6s  %6s  %12s",
          @tag,
          'time', 'total', '%total', '%time', 'avg'
        )

        msgs << ""

        total = @tags.values.inject(0) { |acc, v| acc + v[:count] }
        total_time = @tags.values.inject(0) { |acc, v| acc + v[:time] }

        @tags.values.sort_by { |v| -v[:time] }.each do |tag|
          msgs << format(
            "%15s  %12s  %6d  %6.2f  %6.2f  %12s",
            tag[:val], tag[:time].duration, tag[:count],
            100 * tag[:count].to_f / total,
            100 * tag[:time] / total_time,
            (tag[:time] / tag[:count]).duration
          )
        end

        log :info, msgs.join("\n")
      end
    end
  end
end

# Register TagProf listener
TestProf.activate('TAG_PROF') do
  RSpec.configure do |config|
    listener = TestProf::TagProf::RSpecListener.new

    config.before(:suite) do
      config.reporter.register_listener(
        listener, *TestProf::TagProf::RSpecListener::NOTIFICATIONS
      )
    end

    config.after(:suite) { listener.print }
  end
end
