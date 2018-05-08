# frozen_string_literal: true

require "test_prof/ext/float_duration"
require "test_prof/ext/string_strip_heredoc"

module TestProf::TagProf
  module Printers
    module Simple # :nodoc: all
      class << self
        include TestProf::Logging
        using TestProf::StringStripHeredoc
        using TestProf::FloatDuration

        def dump(result)
          msgs = []

          msgs <<
            <<-MSG.strip_heredoc
              TagProf report for #{result.tag}
            MSG

          msgs << format(
            "%15s  %12s  %6s  %6s  %6s  %12s",
            result.tag,
            'time', 'total', '%total', '%time', 'avg'
          )

          msgs << ""

          total = result.data.values.inject(0) { |acc, v| acc + v[:count] }
          total_time = result.data.values.inject(0) { |acc, v| acc + v[:time] }

          result.data.values.sort_by { |v| -v[:time] }.each do |tag|
            msgs << format(
              "%15s  %12s  %6d  %6.2f  %6.2f  %12s",
              tag[:value], tag[:time].duration, tag[:count],
              100 * tag[:count].to_f / total,
              100 * tag[:time] / total_time,
              (tag[:time] / tag[:count]).duration
            )
          end

          log :info, msgs.join("\n")
        end
      end
    end
  end
end
