# frozen_string_literal: true

require "test_prof/ext/string_strip_heredoc"

using TestProf::StringStripHeredoc

module TestProf::EventProf::CustomEvents
  module SidekiqJobs # :nodoc: all
    module ClientPatch
      def raw_push(*)
        return super unless Sidekiq::Testing.inline?
        SidekiqJobs.track { super }
      end
    end

    class << self
      def setup!
        Sidekiq::Client.prepend ClientPatch
      end

      def track
        ActiveSupport::Notifications.instrument(
          'sidekiq.jobs'
        ) { yield }
      end
    end
  end
end

TestProf.activate('EVENT_PROF', 'sidekiq.jobs') do
  if TestProf.require(
    'sidekiq/testing',
    <<-MSG.strip_heredoc
      Failed to load Sidekiq.

      Make sure that "sidekiq" gem is in your Gemfile.
    MSG
  )
    TestProf::EventProf::CustomEvents::SidekiqJobs.setup!
    TestProf::EventProf.configure do |config|
      config.rank_by = :count
    end
  end
end
