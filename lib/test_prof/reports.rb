# frozen_string_literal: true

require "json"

require "test_prof/version"

module TestProf
  # Registry of JSON reports written during a test run.
  #
  # When the global JSON format is activated (TEST_PROF_FORMAT=json),
  # every JSON report is registered here and a manifest
  # (tmp/test_prof/index.json) is written after the suite,
  # so consumers don't have to parse stdout to find the reports.
  module Reports
    class << self
      def register(profiler, path)
        return unless TestProf.json_format?

        reports << {profiler: profiler, path: path}
        install_hook
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
        @hook_installed = false
      end

      private

      def reports
        @reports ||= []
      end

      def install_hook
        return if @hook_installed

        @hook_installed = true
        at_exit { TestProf::Reports.write }
      end
    end
  end
end
