# frozen_string_literal: true

require "test_prof/utils/sized_ordered_set"
require "test_prof/ext/float_duration"
require "test_prof/ext/string_truncate"

module TestProf # :nodoc: all
  using FloatDuration
  using StringTruncate

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

      def print_result_header
        <<~MSG

          Top #{top_count} slowest suites by setup time:

        MSG
      end

      def print_group_result(group)
        "#{group[:desc].truncate} (#{group[:loc]}) – #{bold(group[:total_setup].duration)} " \
        "of #{group[:total].duration} / #{group[:count]} " \
        "(before: #{(group[:total_setup] - group[:total_lazy_let]).duration}, " \
        "before let: #{group[:total_before_let].duration}, " \
        "lazy let: #{group[:total_lazy_let].duration})"
      end

      def print_results
        msgs = [print_result_header]

        results.each do |group|
          msgs << print_group_result(group)
          msgs << "\n" if group[:top_lets].any?
          group[:top_lets].each do |let|
            msgs << " ↳ #{let[:name]} – #{let[:duration].duration} (#{let[:size]})\n"
          end
          msgs << "\n"
        end

        msgs.join
      end

      private

      # Follow the logger's color setting, so that a report written to a file
      # or a pipe has no escape sequences in it
      def bold(str)
        return str unless TestProf.config.color?

        "\e[1m#{str}\e[22m"
      end
    end
  end
end
