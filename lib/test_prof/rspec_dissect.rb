# frozen_string_literal: true

require "test_prof/rspec_stamp"
require "test_prof/logging"

module TestProf
  # RSpecDissect tracks how much time do you spend in `before` hooks
  # and memoization helpers (i.e. `let`) in your tests.
  module RSpecDissect
    module ExampleInstrumentation # :nodoc:
      def run_before_example(*)
        RSpecDissect.track(:before) { super }
      end
    end

    module MemoizedInstrumentation # :nodoc:
      def fetch_or_store(*)
        res = nil
        Thread.current[:_rspec_dissect_memo_depth] ||= 0
        Thread.current[:_rspec_dissect_memo_depth] += 1
        begin
          res = if Thread.current[:_rspec_dissect_memo_depth] == 1
                  RSpecDissect.track(:memo) { super }
                else
                  super
                end
        ensure
          Thread.current[:_rspec_dissect_memo_depth] -= 1
        end
        res
      end
    end

    # RSpecDisect configuration
    class Configuration
      attr_accessor :top_count

      def initialize
        @top_count = (ENV['RD_PROF_TOP'] || 5).to_i
        @stamp = ENV['RD_PROF_STAMP']

        RSpecStamp.config.tags = @stamp if stamp?
      end

      def stamp?
        !@stamp.nil?
      end
    end

    METRICS = %w[before memo].freeze

    class << self
      include Logging

      def config
        @config ||= Configuration.new
      end

      def configure
        yield config
      end

      def init
        RSpec::Core::Example.prepend(ExampleInstrumentation)
        RSpec::Core::MemoizedHelpers::ThreadsafeMemoized.prepend(MemoizedInstrumentation)
        RSpec::Core::MemoizedHelpers::NonThreadSafeMemoized.prepend(MemoizedInstrumentation)

        @data = {}

        METRICS.each do |type|
          @data["total_#{type}"] = 0.0
        end

        reset!

        log :info, "RSpecDissect enabled"
      end

      def track(type)
        start = TestProf.now
        res = yield
        delta = (TestProf.now - start)
        type = type.to_s
        @data[type] += delta
        @data["total_#{type}"] += delta
        res
      end

      def reset!
        METRICS.each do |type|
          @data[type.to_s] = 0.0
        end
      end

      METRICS.each do |type|
        define_method("#{type}_time") do
          @data[type.to_s]
        end

        define_method("total_#{type}_time") do
          @data["total_#{type}"]
        end
      end
    end
  end
end

require "test_prof/rspec_dissect/rspec" if defined?(RSpec::Core)

TestProf.activate('RD_PROF') do
  TestProf::RSpecDissect.init
end
