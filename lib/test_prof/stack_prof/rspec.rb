# frozen_string_literal: true

module TestProf
  module StackProf
    # Reporter for RSpec to profile specific examples with StackProf
    class Listener # :nodoc:
      NOTIFICATIONS = %i[
        example_started
        example_failed
        example_passed
      ].freeze

      def example_started(notification)
        return unless profile?(notification.example)
        notification.example.metadata[:sprof_report] = TestProf::StackProf.profile
      end

      def example_finished(notification)
        return unless profile?(notification.example)
        return unless notification.example.metadata[:sprof_report] == false

        TestProf::StackProf.dump(
          notification.example.full_description.parameterize
        )
      end

      alias example_passed example_finished
      alias example_failed example_finished

      private

      def profile?(example)
        example.metadata.key?(:sprof)
      end
    end
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    listener = TestProf::StackProf::Listener.new

    config.reporter.register_listener(
      listener, *TestProf::StackProf::Listener::NOTIFICATIONS
    )
  end
end

# Handle boot profiling
RSpec.configure do |config|
  config.append_before(:suite) do
    TestProf::StackProf.dump("boot") if TestProf::StackProf.config.boot?
  end
end
