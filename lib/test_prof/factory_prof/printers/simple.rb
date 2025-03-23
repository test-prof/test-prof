# frozen_string_literal: true

require "test_prof/ext/float_duration"

module TestProf::FactoryProf
  module Printers
    module Simple # :nodoc: all
      class << self
        using TestProf::FloatDuration
        include TestProf::Logging

        def dump(result, start_time:, threshold:, truncate_names:)
          return log(:info, "No factories detected") if result.raw_stats == {}
          msgs = []

          total_run_time = TestProf.now - start_time
          total_count = result.stats.sum { |stat| stat[:total_count] }
          total_top_level_count = result.stats.sum { |stat| stat[:top_level_count] }
          total_time = result.stats.sum { |stat| stat[:top_level_time] }
          total_uniq_factories = result.stats.map { |stat| stat[:name] }.uniq.count

          table_indent = 3
          variations_indent = 2
          max_name_length = result.stats.map { _1[:name].length }.max
          max_variation_length = result.stats.flat_map { _1[:variations] }.select(&:present?).map { _1[:name].length }.max || 0
          name_column_length = truncate_names ? 20 : ([max_name_length, max_variation_length].max + variations_indent)

          msgs <<
            <<~MSG
              Factories usage

               Total: #{total_count}
               Total top-level: #{total_top_level_count}
               Total time: #{total_time.duration} (out of #{total_run_time.duration})
               Total uniq factories: #{total_uniq_factories}
            MSG

          msgs << format(
            "%#{table_indent}s%-#{name_column_length}s %8s %12s %13s %16s %17s",
            "", "name", "total", "top-level", "total time", "time per call", "top-level time"
          )
          msgs << ""

          result.stats.each do |stat|
            next if stat[:total_count] < threshold

            msgs << formatted(
              table_indent,
              name_column_length,
              truncate_names,
              stat
            )

            # move other variation ("[...]") to the end of the array
            sorted_variations = stat[:variations].sort_by.with_index do |variation, i|
              (variation[:name] == "[...]") ? stat[:variations].size + 1 : i
            end
            sorted_variations.each do |variation_stat|
              next if variation_stat[:total_count] < threshold

              msgs << formatted(
                table_indent + variations_indent,
                name_column_length - variations_indent,
                truncate_names,
                variation_stat
              )
            end
          end

          log :info, msgs.join("\n")
        end

        private

        def formatted(indent_len, name_len, truncate_names, stat)
          format(format_string(indent_len, name_len, truncate_names), *format_args(stat))
        end

        def format_args(stat)
          time_per_call = stat[:total_time] / stat[:total_count]
          format_args = [""]
          format_args += stat.values_at(:name, :total_count, :top_level_count, :total_time)
          format_args << time_per_call
          format_args << stat[:top_level_time]
        end

        def format_string(indent_len, name_len, truncate_names)
          name_format = truncate_names ? "#{name_len}.#{name_len}" : name_len.to_s
          "%#{indent_len}s%-#{name_format}s %8d %12d %12.4fs %15.4fs %16.4fs"
        end
      end
    end
  end
end
