# frozen_string_literal: true

require "json"

require "test_prof/version"

module TestProf
  # Registry of JSON reports written during a test run.
  #
  # When the global JSON format is activated (TEST_PROF_FORMAT=json),
  # every JSON report is registered here and the manifest
  # (tmp/test_prof/index.json) is rewritten, so consumers don't have to
  # parse stdout to find the reports.
  #
  # NOTE: The manifest is rewritten on every registration, because some
  # profilers (e.g. FactoryProf) dump their reports from `at_exit` hooks
  # which could run after any after-the-suite logic.
  module Reports
    class << self
      def register(profiler, path)
        return unless TestProf.json_format?

        reports << {profiler: profiler, path: path}
        write
      end

      def write
        return if reports.empty?

        manifest = {
          schema_version: Printers::Json::SCHEMA_VERSION,
          test_prof_version: TestProf::VERSION,
          reports: reports
        }

        path = TestProf.artifact_path("index.json", timestamps: false)

        File.write(path, JSON.generate(manifest))
      end

      def reset!
        @reports = []
      end

      private

      def reports
        @reports ||= []
      end
    end
  end
end
