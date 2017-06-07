# frozen_string_literal: true

require "test_prof/ext/float_duration"

module TestProf
  module FactoryDoctor
    class RSpecListener # :nodoc:
      include Logging
      using FloatDuration

      NOTIFICATIONS = %i[
        example_started
        example_finished
      ].freeze

      def initialize
        @count = 0
        @time = 0.0
        @example_groups = Hash.new { |h, k| h[k] = [] }
      end

      def example_started(_notification)
        FactoryDoctor.start
      end

      def example_finished(notification)
        FactoryDoctor.stop
        return if notification.example.pending?

        result = FactoryDoctor.result

        if result.bad?
          group = notification.example.example_group.parent_groups.last
          notification.example.metadata.merge!(
            factories: result.count,
            time: result.time
          )
          @example_groups[group] << notification.example
          @count += 1
          @time += result.time
        end
      end

      def print
        return if @example_groups.empty?

        msgs = []

        msgs <<
          <<~MSG
            FactoryDoctor report

            Total (potentially) bad examples: #{@count}
            Total wasted time: #{@time.duration}

          MSG

        @example_groups.each do |group, examples|
          msgs << "#{group.description} (#{group.metadata[:location]})\n"
          examples.each do |ex|
            msgs << "  #{ex.description} (#{ex.metadata[:location]}) "\
                    "– #{pluralize_records(ex.metadata[:factories])} created, "\
                    "#{ex.metadata[:time].duration}\n"
          end
          msgs << "\n"
        end

        log :info, msgs.join
      end

      private

      def pluralize_records(count)
        return "1 record" if count == 1
        "#{count} records"
      end
    end
  end
end

# Register FactoryDoctor listener
RSpec.configure do |config|
  listener = TestProf::FactoryDoctor::RSpecListener.new

  config.reporter.register_listener(listener, *TestProf::FactoryDoctor::RSpecListener::NOTIFICATIONS)

  config.after(:suite) { listener.print }
end

RSpec.shared_context "factory_doctor:ignore", fd_ignore: true do
  around(:each) { |ex| TestProf::FactoryDoctor.ignore(&ex) }
end
