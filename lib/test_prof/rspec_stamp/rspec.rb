# frozen_string_literal: true

require "test_prof/ext/string_strip_heredoc"

module TestProf
  module RSpecStamp
    class RSpecListener # :nodoc:
      include Logging
      using StringStripHeredoc

      NOTIFICATIONS = %i[
        example_failed
      ].freeze

      def initialize
        @failed = 0
        @ignored = 0
        @total = 0
        @examples = Hash.new { |h, k| h[k] = [] }
      end

      def example_failed(notification)
        return if notification.example.pending?

        location = notification.example.metadata[:location]

        file, line = location.split(":")

        @examples[file] << line.to_i
      end

      def stamp!
        stamper = Stamper.new

        @examples.each do |file, lines|
          stamper.stamp_file(file, lines.uniq)
        end

        msgs = []

        msgs <<
          <<-MSG.strip_heredoc
            RSpec Stamp results

            Total patches: #{stamper.total}
            Total files: #{@examples.keys.size}

            Failed patches: #{stamper.failed}
            Ignored files: #{stamper.ignored}
          MSG

        log :info, msgs.join
      end
    end
  end
end

# Register EventProf listener
TestProf.activate('RSTAMP') do
  RSpec.configure do |config|
    listener = TestProf::RSpecStamp::RSpecListener.new

    config.before(:suite) do
      config.reporter.register_listener(
        listener, *TestProf::RSpecStamp::RSpecListener::NOTIFICATIONS
      )
    end

    config.after(:suite) { listener.stamp! }
  end
end
