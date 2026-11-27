# frozen_string_literal: true

require "test_prof/ext/float_duration"

module TestProf
  module FactoryDoctor
    module Printers
      module Simple # :nodoc: all
        class << self
          include TestProf::Logging

          using TestProf::FloatDuration

          def dump(results)
            msgs = []

            msgs <<
              <<~MSG
                FactoryDoctor report

                Total (potentially) bad examples: #{results[:total_bad_examples]}
                Total wasted time: #{results[:total_wasted_time].duration}

              MSG

            results[:groups].each do |group|
              msgs << group_header(group)

              group[:examples].each do |example|
                msgs << "  #{example[:description]} (#{example[:location]}) " \
                        "– #{pluralize_records(example[:factories])} created, " \
                        "#{example[:time].duration}\n"
              end
              msgs << "\n"
            end

            log :info, msgs.join
          end

          private

          def group_header(group)
            msg = "#{group[:description]} (#{group[:location]})"

            if group[:total_factories]
              msg += " (#{pluralize_records(group[:total_factories])} created, #{group[:total_time].duration})"
            end

            "#{msg}\n"
          end

          def pluralize_records(count)
            (count == 1) ? "1 record" : "#{count} records"
          end
        end
      end
    end
  end
end
