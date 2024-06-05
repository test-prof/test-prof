# frozen_string_literal: true

require "test_prof/factory_prof/printers/simple"
require "test_prof/factory_prof/printers/flamegraph"
require "test_prof/factory_prof/printers/nate_heckler"
require "test_prof/factory_prof/printers/json"
require "test_prof/factory_prof/factory_builders/factory_bot"
require "test_prof/factory_prof/factory_builders/fabrication"

module TestProf
  # FactoryProf collects "factory stacks" that can be used to build
  # flamegraphs or detect most popular factories
  module FactoryProf
    FACTORY_BUILDERS = [FactoryBuilders::FactoryBot,
      FactoryBuilders::Fabrication].freeze

    # FactoryProf configuration
    class Configuration
      attr_accessor :mode, :printer, :threshold, :include_variations, :variations_limit

      def initialize
        @mode = (ENV["FPROF"] == "flamegraph") ? :flamegraph : :simple
        @printer =
          case ENV["FPROF"]
          when "flamegraph"
            Printers::Flamegraph
          when "nate_heckler"
            Printers::NateHeckler
          when "json"
            Printers::Json
          else
            Printers::Simple
          end
        @threshold = ENV.fetch("FPROF_THRESHOLD", 0).to_i
        @include_variations = ENV["FPROF_VARS"] == "1"
        @variations_limit = ENV.fetch("FPROF_VARIATIONS_LIMIT", 2).to_i
      end

      # Whether we want to generate flamegraphs
      def flamegraph?
        @mode == :flamegraph
      end
    end

    class Result # :nodoc:
      attr_reader :stacks, :raw_stats

      def initialize(stacks, raw_stats)
        @stacks = stacks
        @raw_stats = raw_stats
      end

      # Returns sorted stats
      def stats
        @stats ||= @raw_stats.values.sort_by { |el| -el[:total_count] }.map do |stat|
          unless stat[:variations].empty?
            stat = stat.dup
            stat[:variations] = stat[:variations].values.sort_by { |nested_el| -nested_el[:total_count] }
          end

          stat
        end
      end

      def total_count
        @total_count ||= @raw_stats.values.sum { |v| v[:total_count] }
      end

      def total_time
        @total_time ||= @raw_stats.values.sum { |v| v[:total_time] }
      end
    end

    class << self
      include TestProf::Logging

      def config
        @config ||= Configuration.new
      end

      def configure
        yield config
      end

      # Patch factory lib, init vars
      def init
        @running = false

        log :info, "FactoryProf enabled (#{config.mode} mode)"

        patch!
      end

      def patch!
        return if @patched

        FACTORY_BUILDERS.each(&:patch)

        @patched = true
      end

      # Inits FactoryProf and setups at exit hook,
      # then runs
      def run
        init

        started_at = TestProf.now

        at_exit do
          print(started_at)
        end

        start
      end

      def print(started_at)
        printer = config.printer

        printer.dump(result, start_time: started_at, threshold: config.threshold)
      end

      def start
        reset!
        @running = true
      end

      def stop
        @running = false
      end

      def result
        Result.new(@stacks, @stats)
      end

      def track(factory, variation:)
        return yield unless running?
        @depth += 1
        @current_stack << factory if config.flamegraph?
        track_count(@stats[factory])
        track_count(@stats[factory][:variations][variation_name(variation)]) unless variation.empty?
        t1 = TestProf.now
        begin
          yield
        ensure
          t2 = TestProf.now
          track_time(@stats[factory], t1, t2)
          track_time(@stats[factory][:variations][variation_name(variation)], t1, t2) unless variation.empty?
          @depth -= 1
          flush_stack if @depth.zero?
        end
      end

      private

      def variation_name(variation)
        variations_count = variation.to_s.scan(/[\w]+/).size
        return "[...]" if variations_count > config.variations_limit

        variation
      end

      def reset!
        @stacks = [] if config.flamegraph?
        @depth = 0
        @stats = Hash.new do |h, k|
          h[k] = hash_template(k)
          h[k][:variations] = Hash.new { |hh, variation_key| hh[variation_key] = hash_template(variation_key) }
          h[k]
        end
        flush_stack
      end

      def hash_template(name)
        {
          name: name,
          total_count: 0,
          top_level_count: 0,
          total_time: 0.0,
          top_level_time: 0.0
        }
      end

      def track_count(factory)
        factory[:total_count] += 1
        factory[:top_level_count] += 1 if @depth == 1
      end

      def track_time(factory, t1, t2)
        elapsed = t2 - t1
        factory[:total_time] += elapsed
        factory[:top_level_time] += elapsed if @depth == 1
      end

      def flush_stack
        return unless config.flamegraph?
        @stacks << @current_stack unless @current_stack.nil? || @current_stack.empty?
        @current_stack = []
      end

      def running?
        @running == true
      end
    end
  end
end

TestProf.activate("FPROF") do
  TestProf::FactoryProf.run
end
