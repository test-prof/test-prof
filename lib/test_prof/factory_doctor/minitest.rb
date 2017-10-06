# frozen_string_literal: true

require 'minitest/base_reporter'
require 'test_prof'
require 'test_prof/factory_doctor'
require "test_prof/ext/float_duration"
require "test_prof/ext/string_strip_heredoc"

module Minitest
  module TestProf
    class FactoryDoctorReporter < BaseReporter # :nodoc:
      using ::TestProf::FloatDuration
      using ::TestProf::StringStripHeredoc

      SUCCESS_MESSAGE = 'FactoryDoctor says: "Looks good to me!"'.freeze

      def initialize(io = $stdout, options = {})
        super
        @doctor = configure_doctor
        @count = 0
        @time = 0.0
        @example_groups = Hash.new { |h, k| h[k] = [] }
      end

      def prerecord(_group, _example)
        @doctor.start
      end

      def record(example)
        @doctor.stop
        return if example.skipped?

        result = @doctor.result
        return unless result.bad?

        group = {
          description: example.class.name,
          location: location_without_line_number(example)
        }

        @example_groups[group] << {
          description: example.name.gsub(/^test_(?:\d+_)?/, ''),
          location: location_with_line_number(example),
          factories: result.count,
          time: result.time
        }

        @count += 1
        @time += result.time
      end

      def report
        return log(:info, SUCCESS_MESSAGE) if @example_groups.empty?

        msgs = []

        msgs <<
          <<-MSG.strip_heredoc
            FactoryDoctor report

            Total (potentially) bad examples: #{@count}
            Total wasted time: #{@time.duration}

          MSG

        @example_groups.each do |group, examples|
          msgs << "#{group[:description]} (#{group[:location]})\n"
          examples.each do |ex|
            msgs << "  #{ex[:description]} (#{ex[:location]}) "\
                    "– #{pluralize_records(ex[:factories])} created, "\
                    "#{ex[:time].duration}\n"
          end
          msgs << "\n"
        end

        log :info, msgs.join
      end

      private

      def pluralize_records(count)
        count == 1 ? '1 record' : "#{count} records"
      end

      def configure_doctor
        ::TestProf::FactoryDoctor.init
        ::TestProf::FactoryDoctor
      end
    end
  end
end
