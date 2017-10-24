# frozen_string_literal: true

require "test_prof/ext/string_strip_heredoc"
require "test_prof/factory_bot"

using TestProf::StringStripHeredoc

module TestProf::EventProf::CustomEvents
  module FactoryCreate # :nodoc: all
    module RunnerPatch
      def run(strategy = @strategy)
        return super unless strategy == :create
        FactoryCreate.track(@name) do
          super
        end
      end
    end

    class << self
      def setup!
        @depth = 0
        TestProf::FactoryBot::FactoryRunner.prepend RunnerPatch
      end

      def track(factory)
        @depth += 1
        res = nil
        begin
          res =
            if @depth == 1
              ActiveSupport::Notifications.instrument(
                'factory.create',
                name: factory
              ) { yield }
            else
              yield
            end
        ensure
          @depth -= 1
        end
        res
      end
    end
  end
end

TestProf.activate('EVENT_PROF', 'factory.create') do
  if defined? TestProf::FactoryBot
    TestProf::EventProf::CustomEvents::FactoryCreate.setup!
  else
    TestProf.log(:error,
                 <<-MSG.strip_heredoc
                   Failed to load factory_bot / factory_girl.

                   Make sure that any of them is in your Gemfile.
                 MSG
                )
  end
end
