# frozen_string_literal: true

require "minitest/base_reporter"

module Minitest
  module TestProf # :nodoc:
    # Add fd_ignore methods
    module FactoryDoctorIgnore
      def fd_ignore
        ::TestProf::FactoryDoctor.ignore!
      end
    end

    Minitest::Test.include FactoryDoctorIgnore

    class FactoryDoctorReporter < BaseReporter # :nodoc:
      SUCCESS_MESSAGE = 'FactoryDoctor says: "Looks good to me!"'

      def initialize(io = $stdout, options = {})
        super
        ::TestProf::FactoryDoctor.init
        @count = 0
        @time = 0.0
        @example_groups = Hash.new { |h, k| h[k] = [] }
      end

      def prerecord(_group, _example)
        ::TestProf::FactoryDoctor.start
      end

      def record(example)
        ::TestProf::FactoryDoctor.stop
        return if example.skipped? || ::TestProf::FactoryDoctor.ignore?

        result = ::TestProf::FactoryDoctor.result
        return unless result.bad?

        # Minitest::Result (>= 5.11) has `klass` method
        group_name = example.respond_to?(:klass) ? example.klass : example.class.name

        group = {
          description: group_name,
          location: location_without_line_number(example)
        }

        @example_groups[group] << {
          description: example.name.gsub(/^test_(?:\d+_)?/, ""),
          location: location_with_line_number(example),
          factories: result.count,
          time: result.time
        }

        @count += 1
        @time += result.time
      end

      def report
        return log(:info, SUCCESS_MESSAGE) if @example_groups.empty?

        printer.dump(results)
      end

      private

      def results
        {
          total_bad_examples: @count,
          total_wasted_time: @time,
          groups: @example_groups.map do |group, examples|
            {
              description: group[:description],
              location: group[:location],
              examples: examples
            }
          end
        }
      end

      def printer
        @printer ||= ::TestProf.json_format? ? ::TestProf::FactoryDoctor::Printers::Json : ::TestProf::FactoryDoctor::Printers::Simple
      end
    end
  end
end
