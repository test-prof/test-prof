# frozen_string_literal: true

require "test_prof/tps_prof/profiler"
require "test_prof/tps_prof/reporter/text"

module TestProf
  # TPSProf shows top-N example group based on their tests-per-second value.
  #
  # Example:
  #
  #   # Show top-10 groups with the worst TPS
  #   TPS_PROF=10 rspec ...
  #
  #   # Report (as errors) groups with lower TPS
  #   TPS_PROF_MIN_TPS=10 TPS_PROF=strict rspec ...
  module TPSProf
    class Configuration
      attr_accessor :top_count, :reporter, :mode

      # Thresholds
      attr_accessor(
        :min_examples_count, # Ignore groups with fewer examples
        :min_group_time,     # Ignore groups with less total time (in seconds)
        :min_target_tps,     # Ignore groups with higher TPS
        :max_examples_count, # Report groups with more examples in strict mode
        :max_group_time,     # Report groups with more total time in strict mode
        :min_tps             # Report groups with lower TPS in strict mode
      )

      def initialize
        @mode = (ENV["TPS_PROF_MODE"] || ((ENV["TPS_PROF"] == "strict") ? :strict : :profile)).to_sym
        @top_count = ENV["TPS_PROF_COUNT"]&.to_i || ((ENV["TPS_PROF"].to_i > 1) ? ENV["TPS_PROF"].to_i : nil) || 10

        @min_examples_count = ENV.fetch("TPS_PROF_MIN_EXAMPLES", 10).to_i
        @min_group_time = ENV.fetch("TPS_PROF_MIN_TIME", 5).to_i
        @min_target_tps = ENV.fetch("TPS_PROF_TARGET_TPS", 30).to_i

        @max_examples_count = ENV["TPS_PROF_MAX_EXAMPLES"]&.to_i
        @max_group_time = ENV["TPS_PROF_MAX_TIME"]&.to_i
        @min_tps = ENV["TPS_PROF_MIN_TPS"]&.to_i

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
