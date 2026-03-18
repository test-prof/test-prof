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
    class Error < StandardError; end

    class GroupInfo < Struct.new(:group, :location, :examples_count, :total_time, :tps, :penalty, keyword_init: true)
    end

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

      attr_reader :custom_strict_handler

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

      def strict_handler
        @strict_handler ||= method(:default_strict_handler)
      end

      def strict_handler=(val)
        @strict_handler = val
        @custom_strict_handler = true
      end

      private

      def resolve_reporter(format)
        # TODO: support other formats
        TPSProf::Reporter::Text.new
      end

      def default_strict_handler(group_info)
        error_msg = nil
        location = group_info.location

        if max_examples_count && group_info.examples_count > max_examples_count
          error_msg ||= "Group #{location} has too many examples: #{group_info.examples_count} > #{max_examples_count}"
        end

        if max_group_time && group_info.total_time > max_group_time
          error_msg ||= "Group #{location} has too long total time: #{group_info.total_time} > #{max_group_time}"
        end

        if min_tps && group_info.tps < min_tps
          error_msg ||= "Group #{location} has too low TPS: #{group_info.tps} < #{min_tps}"
        end

        raise error_msg if error_msg
      end
    end

    class << self
      def config
        @config ||= Configuration.new
      end

      def configure
        yield config
      end

      def handle_group_strictly(group_info)
        reporter = ::RSpec.configuration.reporter
        config.strict_handler.call(group_info)
        false
      rescue => err
        reporter.notify_non_example_exception(Error.new(err.message), "")
        true
      end
    end
  end
end

require "test_prof/tps_prof/rspec" if TestProf.rspec?
# TODO: Minitest support
# require "test_prof/tps_prof/minitest" if TestProf.minitest?
