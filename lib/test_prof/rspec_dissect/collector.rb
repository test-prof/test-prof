# frozen_string_literal: true

require "test_prof/utils/sized_ordered_set"

module TestProf # :nodoc: all
  module RSpecDissect
    class Collector
      attr_reader :results, :name, :top_count

      def initialize(top_count:)
        @top_count = top_count
        @results = Utils::SizedOrderedSet.new(
          top_count, sort_by: :total_setup
        )
      end

      def <<(data)
        results << data
      end
    end
  end
end
