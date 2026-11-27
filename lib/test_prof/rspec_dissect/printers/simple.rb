# frozen_string_literal: true

require "test_prof/ext/float_duration"
require "test_prof/ext/string_truncate"

module TestProf
  module RSpecDissect
    module Printers
      module Simple # :nodoc: all
        class << self
          include TestProf::Logging

          using TestProf::FloatDuration
          using TestProf::StringTruncate

          def dump(results)
            msgs = []

            msgs <<
              <<~MSG
                RSpecDissect report

                Total time: #{results[:total_time].duration}
                Total setup time: #{results[:total_setup_time].duration}
              MSG

            msgs << "\n"

            msgs << print_groups(results)

            log :info, msgs.join
          end

          private

          def print_groups(results)
            msgs = [
              <<~MSG

                Top #{results[:top_count]} slowest suites by setup time:

              MSG
            ]

            results[:groups].each do |group|
              msgs << print_group_result(group)
              msgs << "\n" if group[:top_lets].any?
              group[:top_lets].each do |let|
                msgs << " ↳ #{let[:name]} – #{let[:duration].duration} (#{let[:size]})\n"
              end
              msgs << "\n"
            end

            msgs.join
          end

          def print_group_result(group)
            "#{group[:description].truncate} (#{group[:location]}) – #{bold(group[:setup_time].duration)} " \
            "of #{group[:time].duration} / #{group[:count]} " \
            "(before: #{group[:before_time].duration}, " \
            "before let: #{group[:before_let_time].duration}, " \
            "lazy let: #{group[:lazy_let_time].duration})"
          end

          # Follow the logger's color setting, so that a report written to a file
          # or a pipe has no escape sequences in it
          def bold(str)
            return str unless TestProf.config.color?

            "\e[1m#{str}\e[22m"
          end
        end
      end
    end
  end
end
