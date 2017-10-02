# frozen_string_literal: true

require "test_prof/factory_prof/printers/simple"
require "test_prof/factory_prof/printers/flamegraph"
require "test_prof/factory_prof/factory_builders/factory_girl"
require "test_prof/factory_prof/factory_builders/fabrication"

module TestProf
  # FactoryProf collects "factory stacks" that can be used to build
  # flamegraphs or detect most popular factories
  module FactoryProf
    FACTORY_BUILDERS = [FactoryBuilders::FactoryGirl,
                        FactoryBuilders::Fabrication].freeze

    # FactoryProf configuration
    class Configuration
      attr_accessor :mode

      def initialize
        @mode = ENV['FPROF'] == 'flamegraph' ? :flamegraph : :simple
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
        return @stats if instance_variable_defined?(:@stats)

        @stats = @raw_stats.values
                           .sort_by { |el| -el[:total] }
      end

      def total
        return @total if instance_variable_defined?(:@total)
        @total = @raw_stats.values.sum { |v| v[:total] }
      end

      private

      def sorted_stats(key)
        @raw_stats.values
                  .map { |el| [el[:name], el[key]] }
                  .sort_by { |el| -el[1] }
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

        FACTORY_BUILDERS.each(&:patch)
      end

      # Inits FactoryProf and setups at exit hook,
      # then runs
      def run
        init

        printer = config.flamegraph? ? Printers::Flamegraph : Printers::Simple

        at_exit { printer.dump(result) }

        start
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

      def track(factory)
        return yield unless running?
        begin
          @depth += 1
          @current_stack << factory if config.flamegraph?
          @stats[factory][:total] += 1
          @stats[factory][:top_level] += 1 if @depth == 1
          yield
        ensure
          @depth -= 1
          flush_stack if @depth.zero?
        end
      end

      private

      def reset!
        @stacks = [] if config.flamegraph?
        @depth = 0
        @stats = Hash.new { |h, k| h[k] = { name: k, total: 0, top_level: 0 } }
        flush_stack
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

TestProf.activate('FPROF') do
  TestProf::FactoryProf.run
end
