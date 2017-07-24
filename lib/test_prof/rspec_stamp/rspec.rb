# frozen_string_literal: true

module TestProf
  module RSpecStamp
    class RSpecListener # :nodoc:
      include Logging

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
        @examples.each do |file, lines|
          stamp_file(file, lines.uniq)
        end

        msgs = []

        msgs <<
          <<~MSG
            RSpec Stamp results

            Total patches: #{@total}
            Total files: #{@examples.keys.size}

            Failed patches: #{@failed}
            Ignored files: #{@ignored}
          MSG

        log :info, msgs.join
      end

      private

      def stamp_file(file, lines)
        @total += lines.size
        return if ignored?(file)

        log :info, "(dry-run) Patching #{file}" if dry_run?

        code = File.readlines(file)

        @failed += RSpecStamp.apply_tags(code, lines, RSpecStamp.config.tags)

        File.write(file, code.join) unless dry_run?
      end

      def ignored?(file)
        ignored = RSpecStamp.config.ignore_files.find do |pattern|
          file =~ pattern
        end

        return unless ignored
        log :warn, "Ignore stamping file: #{file}"
        @ignored += 1
      end

      def dry_run?
        RSpecStamp.config.dry_run?
      end
    end
  end
end

# Register EventProf listener
TestProf.activate('RSTAMP') do
  RSpec.configure do |config|
    listener = TestProf::RSpecStamp::RSpecListener.new

    config.before(:suite) do
      config.reporter.register_listener(listener, *TestProf::RSpecStamp::RSpecListener::NOTIFICATIONS)
    end

    config.after(:suite) { listener.stamp! }
  end
end
