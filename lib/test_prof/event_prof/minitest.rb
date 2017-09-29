# frozen_string_literal: true

require 'test_prof/logging'
require 'test_prof/event_prof/formatters/minitest'

module Minitest
  class EventProfReporter < AbstractReporter # :nodoc:
    include TestProf::Logging

    def initialize(options)
      @profiler = configure_profiler(options)
      @formatter = TestProf::EventProf::MinitestFormatter.new(@profiler)
      @current_group = nil
      @current_example = nil
    end

    def prerecord(group, example)
      change_current_group(group, example) unless @current_group
      track_current_example(group, example)
    end

    def record(*)
      @profiler.example_finished(@current_example)
    end

    def report
      @profiler.group_finished(@current_group)
      result = @formatter.prepare_results

      log :info, result
    end

    private

    def track_current_example(group, example)
      unless @current_group[:name] == group.name
        @profiler.group_finished(@current_group)
        change_current_group(group, example)
      end

      @current_example = {
        name: example.gsub(/^test_\d+_/, ''),
        location: File.expand_path(location(group, example).join(':')).gsub(Dir.getwd, '.')
      }

      @profiler.example_started(@current_example)
    end

    def change_current_group(group, example)
      @current_group = {
        name: group.name,
        location: File.expand_path(location(group, example).first).gsub(Dir.getwd, '.')
      }

      @profiler.group_started(@current_group)
    end

    def location(group, example)
      name = group.public_instance_methods(false).find { |mtd| mtd.to_s == example }
      group.instance_method(name).source_location
    end

    def configure_profiler(options)
      TestProf::EventProf.configure do |config|
        config.event = options[:event]
        config.rank_by = options[:rank_by] if options[:rank_by]
        config.top_count = options[:top_count] if options[:top_count]
        config.per_example = options[:per_example] if options[:per_example]
      end
      TestProf::EventProf.build
    end
  end
end
