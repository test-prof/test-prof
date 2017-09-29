# frozen_string_literal: true

require 'test_prof/event_prof/minitest'

module Minitest
  def self.plugin_event_prof_options(opts, options)
    opts.on "--event-prof=EVENT", "Collects metrics for specified EVENT" do |event|
      options[:event] = event
    end
    opts.on "--event-prof-rank=RANK_BY", "Defines RANK_BY parameter for results" do |rank|
      options[:rank_by] = rank.to_sym
    end
    opts.on "--event-prof-top-count=N", "Limits results with N groups/examples" do |count|
      options[:top_count] = count.to_i
    end
    opts.on "--event-prof-per-example", TrueClass, "Includes examples metrics to results" do |flag|
      options[:per_example] = flag
    end

  end

  def self.plugin_event_prof_init(options)
    options[:event] = ENV['EVENT_PROF'] if ENV['EVENT_PROF']
    options[:rank_by] = ENV['EVENT_PROF_RANK'].to_sym if ENV['EVENT_PROF_RANK']
    options[:top_count] = ENV['EVENT_PROF_TOP'].to_i if ENV['EVENT_PROF_TOP']
    options[:per_example] = true if ENV['EVENT_PROF_EXAMPLES']

    self.reporter << EventProfReporter.new(options) if options[:event]
  end
end
