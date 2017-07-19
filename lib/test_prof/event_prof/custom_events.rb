# frozen_string_literal: true

# TODO: Make it work with Spring
require "test_prof/event_prof/custom_events/factory_create" if ENV['EVENT_PROF'] == "factory.create"
require "test_prof/event_prof/custom_events/sidekiq_inline" if ENV['EVENT_PROF'] == "sidekiq.inline"
require "test_prof/event_prof/custom_events/sidekiq_jobs" if ENV['EVENT_PROF'] == "sidekiq.jobs"
