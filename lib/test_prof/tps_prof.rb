# frozen_string_literal: true

require "test_prof/tps_prof/profiler"
require "test_prof/tps_prof/reporter/text"

module TestProf
  # TPSProf shows top-N example group based on their tests-per-second value.
  #
  # Example:
  #
  #   TPS_PROF=10 rspec ...
  #
  module TPSProf
    class Configuration
      attr_accessor :top_count, :threshold, :reporter

      def initialize
        @top_count = ENV["TPS_PROF"].to_i
        @top_count = 10 if @top_count == 1
        @threshold = ENV.fetch("TPS_PROF_MIN", 10).to_i
        @reporter = resolve_reporter(ENV["TPS_PROF_FORMAT"])
      end

      private

      def resolve_reporter(format)
        # TODO: support other formats
        TPSProf::Reporter::Text.new
      end
    end

    class << self
      def config
        @config ||= Configuration.new
      end

      def configure
        yield config
      end
    end
  end
end

require "test_prof/tps_prof/rspec" if TestProf.rspec?
# TODO: Minitest support
# require "test_prof/tps_prof/minitest" if TestProf.minitest?
