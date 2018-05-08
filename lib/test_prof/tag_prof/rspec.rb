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
        @result = Result.new ENV['TAG_PROF'].to_sym
        @printer = ENV['TAG_PROF_FORMAT'] == 'html' ? Printers::HTML : Printers::Simple

        log :info, "TagProf enabled (#{result.tag})"
      end

      def example_started(_notification)
        @ts = TestProf.now
      end

      def example_finished(notification)
        tag = notification.example.metadata.fetch(result.tag, :__unknown__)

        result.track(tag, time: TestProf.now - @ts)
      end

      # NOTE: RSpec < 3.4.0 doesn't have example_finished event
      alias example_passed example_finished
      alias example_failed example_finished

      def report
        printer.dump(result)
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
