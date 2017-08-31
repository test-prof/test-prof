# frozen_string_literal: true

require "test_prof/ext/float_duration"
require "test_prof/ext/string_truncate"
require "test_prof/ext/string_strip_heredoc"

module TestProf
  module EventProf
    class RSpecListener # :nodoc:
      include Logging
      using FloatDuration
      using StringTruncate
      using StringStripHeredoc

      NOTIFICATIONS = %i[
        example_group_started
        example_group_finished
        example_started
        example_finished
      ].freeze

      def initialize
        @profiler = EventProf.build
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
        result = @profiler.results

        msgs = []

        msgs <<
          <<-MSG.strip_heredoc
            EventProf results for #{@profiler.event}

            Total time: #{@profiler.total_time.duration}
            Total events: #{@profiler.total_count}

            Top #{@profiler.top_count} slowest suites (by #{@profiler.rank_by}):

          MSG

        result[:groups].each do |group|
          description = group[:id].top_level_description
          location = group[:id].metadata[:location]

          msgs <<
            <<-GROUP.strip_heredoc
              #{description.truncate} (#{location}) – #{group[:time].duration} (#{group[:count]} / #{group[:examples]})
            GROUP
        end

        if result[:examples]
          msgs << "\nTop #{@profiler.top_count} slowest tests (by #{@profiler.rank_by}):\n\n"

          result[:examples].each do |example|
            description = example[:id].description
            location = example[:id].metadata[:location]
            msgs <<
              <<-GROUP.strip_heredoc
                #{description.truncate} (#{location}) – #{example[:time].duration} (#{example[:count]})
              GROUP
          end
        end

        log :info, msgs.join

        stamp! if EventProf.config.stamp?
      end

      def stamp!
        result = @profiler.results

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
          <<-MSG.strip_heredoc
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
TestProf.activate('EVENT_PROF') do
  RSpec.configure do |config|
    listener = TestProf::EventProf::RSpecListener.new

    config.before(:suite) do
      config.reporter.register_listener(
        listener, *TestProf::EventProf::RSpecListener::NOTIFICATIONS
      )
    end

    config.after(:suite) { listener.print }
  end
end
