# frozen_string_literal: true

unless "".respond_to?(:parameterize)
  require "test_prof/ext/string_parameterize"
  using TestProf::StringParameterize
end

module TestProf
  module RubyProf
    # Reporter for RSpec to profile specific examples with RubyProf
    class Listener # :nodoc:
      NOTIFICATIONS = %i[
        example_started
        example_finished
      ].freeze

      def example_started(notification)
        return unless profile?(notification.example)
        notification.example.metadata[:rprof_report] =
          TestProf::RubyProf.profile
      end

      def example_finished(notification)
        return unless profile?(notification.example)
        notification.example.metadata[:rprof_report]&.dump(
          ::RSpec::Core::Metadata.id_from(notification.example.metadata).parameterize
        )
      end

      private

      def profile?(example)
        example.metadata.key?(:rprof)
      end
    end
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    listener = TestProf::RubyProf::Listener.new

    config.reporter.register_listener(
      listener, *TestProf::RubyProf::Listener::NOTIFICATIONS
    )
  end
end
