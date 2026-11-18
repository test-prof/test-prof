# frozen_string_literal: true

require "json"

require "test_prof/version"
require "test_prof/logging"
require "test_prof/reports"

module TestProf
  module Printers
    # Base module for JSON printers.
    #
    # Wraps a profiler-specific payload into a uniform envelope:
    #
    #   {
    #     "profiler": "<profiler name>",
    #     "schema_version": 1,
    #     "test_prof_version": "<gem version>",
    #     "data": { ... }
    #   }
    module Json
      SCHEMA_VERSION = 1

      include TestProf::Logging

      private

      def dump_json(profiler, data, filename:)
        envelope = {
          profiler: profiler,
          schema_version: SCHEMA_VERSION,
          test_prof_version: TestProf::VERSION,
          data: data
        }

        outpath = TestProf.artifact_path(filename, timestamps: false)

        File.write(outpath, JSON.generate(envelope))

        log :info, "Report written: profiler=#{profiler} path=#{outpath}"

        TestProf::Reports.register(profiler, outpath)

        outpath
      end
    end
  end
end
