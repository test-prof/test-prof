# frozen_string_literal: true

module TestProf
  # StackProf wrapper.
  #
  # Has 2 modes: global and per-example.
  #
  # Example:
  #
  #   # To activate global profiling you can use env variable
  #   TEST_STACK_PROF=1 rspec ...
  #
  #   # or in your code
  #   TestProf::StackProf.run
  #
  # To profile a specific examples add :sprof tag to it:
  #
  #   it "is doing heavy stuff", :sprof do
  #     ...
  #   end
  #
  module StackProf
    # StackProf configuration
    class Configuration
      attr_accessor :mode, :interval, :raw

      def initialize
        @mode = :wall
        @raw = false
      end
    end

    class << self
      include Logging

      def config
        @config ||= Configuration.new
      end

      def configure
        yield config
      end

      # Run StackProf and automatically dump
      # a report when the process exits.
      #
      # Use this method to profile the whole run.
      def run
        return unless profile

        @locked = true

        log :info, "StackProf enabled"

        at_exit { dump("total") }
      end

      def profile(name = nil)
        return if locked?
        return unless init_stack_prof

        options = {
          mode: config.mode,
          raw: config.raw
        }

        options[:interval] = config.interval if config.interval

        if block_given?
          options[:out] = build_path(name)
          ::StackProf.run(options) { yield }
        else
          ::StackProf.start(options)
        end
        true
      end

      def dump(name)
        ::StackProf.stop

        path = build_path(name)

        ::StackProf.results(path)

        log :info, "StackProf report generated: #{path}"
      end

      private

      def build_path(name)
        TestProf.with_timestamps(
          File.join(
            TestProf.config.output_dir,
            "stack-prof-report-#{config.mode}-#{name}.dump"
          )
        )
      end

      def locked?
        @locked == true
      end

      def init_stack_prof
        return @initialized if instance_variable_defined?(:@initialized)
        @initialized = TestProf.require(
          'stackprof',
          <<~MSG
            Please, install 'stackprof' first:
               # Gemfile
              gem 'stackprof', require: false
          MSG
        )
      end
    end
  end
end

require "test_prof/stack_prof/rspec" if defined?(RSpec)

# Hook to run StackProf globally
TestProf::StackProf.run if ENV['TEST_STACK_PROF']
