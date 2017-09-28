# frozen_string_literal: true

require 'test_prof/event_prof/minitest'

module Minitest
  def self.plugin_event_prof_options(opts, options)
    opts.on "--event-prof=EVENT", "Collects metrics for specified EVENT" do |val|
      options[:event_prof] = val
    end
    opts.on "--event-prof-rank=RANK_BY", "Defines RANK_BY parameter for results" do |val|
      options[:event_prof_rank] = val
    end
  end

  def self.plugin_event_prof_init(options)
    options[:event_prof] = ENV['EVENT_PROF'] if ENV['EVENT_PROF']
    self.reporter << EventProfReporter.new(options) if options[:event_prof]
  end
end
