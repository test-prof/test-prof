# frozen_string_literal: true

require "test_prof/factory_prof/factory_girl_patch"

module TestProf
  # FactoryProf collects "factory stacks" that can be used to build
  # flamegraphs or detect most popular factories
  module FactoryProf
    # FactoryProf configuration
    class Configuration
      attr_accessor :mode

      def initialize
        @mode = ENV['FPROF'] == 'flamegraph' ? :flamegraph : :simple
      end

      # Whether to collect stacks
      def stacks?
        @mode == :flamegraph
      end
    end

    class Result # :nodoc:
      attr_reader :stacks

      def initialize(stacks, raw_stats)
        @stacks = stacks
        @raw_stats = raw_stats
      end

      # Returns sorted stats
      def stats
        return @stats if instance_variable_defined?(:@stats)

        @stats = {
          total: sorted_stats(:total),
          top_level: sorted_stats(:top_level)
        }
      end

      private

      def sorted_stats(key)
        @raw_stats.values
                  .map { |el| [el[:name], el[key]] }
                  .sort_by { |el| -el[1] }
      end
    end

    class Stack # :nodoc:
      attr_reader :fingerprint, :data

      def initialize
        @data = []
        @fingerprint = ''
      end

      def <<(sample)
        @fingerprint += ":#{sample}"
        @data << sample
      end

      def present?
        !@data.empty?
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
        reset!

        log :info, "FactoryProf enabled with #{config.mode} mode"

        # Monkey-patch FactoryGirl
        ::FactoryGirl::FactoryRunner.prepend(FactoryGirlPatch) if
          defined?(::FactoryGirl)
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

      def track(strategy, factory)
        return yield if !running? || (strategy != :create)
        @depth += 1
        @current_stack << factory if config.stacks?
        @stats[factory][:total] += 1
        @stats[factory][:top_level] += 1 if @depth == 1
        yield
      ensure
        @depth -= 1
        flush_stack if @depth.zero?
      end

      private

      def reset!
        @stacks = [] if config.stacks?
        @depth = 0
        @stats = Hash.new { |h, k| h[k] = { name: k, total: 0, top_level: 0 } }
        flush_stack
      end

      def flush_stack
        return unless config.stacks?
        @stacks << @current_stack if @current_stack&.present?
        @current_stack = Stack.new
      end

      def running?
        @running == true
      end
    end
  end
end

require "test_prof/factory_prof/rspec" if defined?(RSpec)
require "test_prof/factory_prof/minitest" if defined?(Minitest::Reporters)

TestProf.activate('FPROF') do
  TestProf::FactoryProf.init
end
