# frozen_string_literal: true

require "test_prof/printers/json"

module TestProf
  module MemoryProf
    class JsonPrinter # :nodoc: all
      include TestProf::Logging
      include TestProf::Printers::Json

      attr_reader :tracker

      def initialize(tracker)
        @tracker = tracker
      end

      def print
        dump_json("memory_prof", data, filename: "memory-prof.json")
      end

      private

      def data
        {
          mode: MemoryProf.config.mode,
          top_count: tracker.top_count,
          total: tracker.total_memory,
          groups: tracker.groups.map { |item| convert(item) },
          examples: tracker.examples.map { |item| convert(item) }
        }
      end

      def convert(item)
        {name: item[:name], location: item[:location], memory: item[:memory]}
      end
    end
  end
end
