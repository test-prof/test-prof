# frozen_string_literal: true

module TestProf::EventProf::CustomEvents
  module SidekiqJobs
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

if TestProf.require(
  'sidekiq/testing',
  <<~MSG
    Failed to load Sidekiq.

    Make sure that "sidekiq" gem is in your Gemfile.
  MSG
)
  TestProf::EventProf::CustomEvents::SidekiqJobs.setup!
  TestProf::EventProf.configure do |config|
    config.rank_by = :count
  end
end
