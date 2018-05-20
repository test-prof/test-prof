# frozen_string_literal: true

require "test_prof/ext/string_strip_heredoc"

using TestProf::StringStripHeredoc

module TestProf::EventProf::CustomEvents
  module SidekiqInline # :nodoc: all
    module ClientPatch
      def raw_push(*)
        return super unless Sidekiq::Testing.inline?
        SidekiqInline.track { super }
      end
    end

    class << self
      def setup!
        @depth = 0
        Sidekiq::Client.prepend ClientPatch
      end

      def track
        @depth += 1
        res = nil
        begin
          res =
            if @depth == 1
              ActiveSupport::Notifications.instrument(
                'sidekiq.inline'
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

TestProf::EventProf::CustomEvents.register("sidekiq.inline") do
  if TestProf.require(
    'sidekiq/testing',
    <<-MSG.strip_heredoc
      Failed to load Sidekiq.

      Make sure that "sidekiq" gem is in your Gemfile.
    MSG
  )
    TestProf::EventProf::CustomEvents::SidekiqInline.setup!
  end
end
