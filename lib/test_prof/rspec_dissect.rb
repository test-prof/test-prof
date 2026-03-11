# frozen_string_literal: true

require "test_prof/rspec_stamp"
require "test_prof/logging"

module TestProf
  # RSpecDissect tracks how much time do you spend in `before` hooks
  # and memoization helpers (i.e. `let`) in your tests.
  module RSpecDissect
    class Span < Struct.new(:id, :parent_id, :type, :duration, :meta)
    end

    module ExampleInstrumentation # :nodoc:
      def run_before_example(*)
        RSpecDissect.track(:before) { super }
      end
    end

    module MemoizedInstrumentation # :nodoc:
      def fetch_or_store(id, *)
        return super if id == :subject
        return @memoized[id] if @memoized[id]

        res = nil
        Thread.current[:_rspec_dissect_let_depth] ||= 0
        Thread.current[:_rspec_dissect_let_depth] += 1
        begin
          res = if Thread.current[:_rspec_dissect_let_depth] == 1
            RSpecDissect.track(:let, name: id) { super }
          else
            super
          end
        ensure
          Thread.current[:_rspec_dissect_let_depth] -= 1
        end
        res
      end
    end

    # RSpecDisect configuration
    class Configuration
      attr_accessor :top_count, :let_stats_enabled,
        :let_top_count

      alias_method :let_stats_enabled?, :let_stats_enabled

      def initialize
        @let_stats_enabled = true
        @let_top_count = (ENV["RD_PROF_LET_TOP"] || 3).to_i
        @top_count = (ENV["RD_PROF_TOP"] || 5).to_i
        @stamp = ENV["RD_PROF_STAMP"]

        RSpecStamp.config.tags = @stamp if stamp?
      end

      def stamp?
        !@stamp.nil?
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

      def init
        RSpec::Core::Example.prepend(ExampleInstrumentation)

        RSpec::Core::MemoizedHelpers::ThreadsafeMemoized.prepend(MemoizedInstrumentation)
        RSpec::Core::MemoizedHelpers::NonThreadSafeMemoized.prepend(MemoizedInstrumentation)

        reset!

        log :info, "RSpecDissect enabled"
      end

      def nextid
        @last_id += 1
        @last_id.to_s
      end

      def current_span
        Thread.current[:_rspec_dissect_spans_stack].last
      end

      def span_stack
        Thread.current[:_rspec_dissect_spans_stack]
      end

      def track(type, id: nextid, **meta)
        span = Span.new(id, current_span&.id, type, 0.0, meta)
        span_stack << span

        begin
          start = TestProf.now
          res = yield
          delta = (TestProf.now - start)
          span.duration = delta
          @spans << span
          res
        ensure
          span_stack.pop
        end
      end

      def populate_from_spans!(data)
        data[:total_setup] = @spans.select { !_1.parent_id }.sum(&:duration)
        data[:total_before_let] = @spans.select { _1.type == :let && _1.parent_id }.sum(&:duration).to_f
        data[:total_lazy_let] = @spans.select { _1.type == :let && !_1.parent_id }.sum(&:duration).to_f

        data[:top_lets] = @spans.select { _1.type == :let }
          .group_by { _1.meta[:name] }
          .transform_values! do |spans|
            {name: spans.first.meta[:name], duration: spans.sum(&:duration), size: spans.size}
          end
          .values
          .sort_by { -_1[:duration] }
          .take(RSpecDissect.config.let_top_count)
      end

      def reset!
        @last_id = 1
        @spans = []
        Thread.current[:_rspec_dissect_spans_stack] = []
      end
    end
  end
end

require "test_prof/rspec_dissect/rspec"

TestProf.activate("RD_PROF") do
  TestProf::RSpecDissect.init
end
