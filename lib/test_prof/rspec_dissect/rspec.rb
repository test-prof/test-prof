# frozen_string_literal: true

require "test_prof/rspec_dissect/collector"

require "test_prof/ext/float_duration"

module TestProf
  module RSpecDissect
    class Listener # :nodoc:
      include Logging

      using FloatDuration

      NOTIFICATIONS = %i[
        example_group_finished
        example_finished
      ].freeze

      def initialize
        @collector = Collector.new(top_count: top_count)

        @examples_count = 0
        @examples_time = 0.0
        @total_examples_time = 0.0
        @total_setup_time = 0.0
      end

      def example_finished(notification)
        @examples_count += 1
        @examples_time += notification.example.execution_result.run_time
      end

      def example_group_finished(notification)
        return unless notification.group.top_level?

        data = {}
        data[:total] = @examples_time
        data[:count] = @examples_count
        data[:desc] = notification.group.top_level_description
        data[:loc] = notification.group.metadata[:location]

        RSpecDissect.populate_from_spans!(data)

        collector << data

        @total_setup_time += data[:total_setup]
        @total_examples_time += @examples_time
        @examples_count = 0
        @examples_time = 0.0

        RSpecDissect.reset!
      end

      def print
        msgs = []

        msgs <<
          <<~MSG
            RSpecDissect report

            Total time: #{@total_examples_time.duration}
            Total setup time: #{@total_setup_time.duration}
          MSG

        msgs << "\n"

        msgs << collector.print_results

        log :info, msgs.join

        stamp! if RSpecDissect.config.stamp?
      end

      def stamp!
        stamper = RSpecStamp::Stamper.new

        examples = Hash.new { |h, k| h[k] = [] }

        results = collector.results.to_a

        results
          .map { |obj| obj[:loc] }.each do |location|
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

      private

      attr_reader :collector

      def top_count
        RSpecDissect.config.top_count
      end
    end
  end
end

# Register RSpecDissect listener
TestProf.activate("RD_PROF") do
  RSpec.configure do |config|
    listener = nil

    config.before(:suite) do
      listener = TestProf::RSpecDissect::Listener.new

      config.reporter.register_listener(
        listener, *TestProf::RSpecDissect::Listener::NOTIFICATIONS
      )
    end

    config.after(:suite) { listener&.print }
  end
end
