# frozen_string_literal: true

require "test_prof/ext/float_duration"

module TestProf::FactoryProf
  module Printers
    module Simple # :nodoc: all
      class << self
        using TestProf::FloatDuration
        include TestProf::Logging

        def dump(result, start_time:, threshold:)
          return log(:info, "No factories detected") if result.raw_stats == {}
          msgs = []

          total_run_time = TestProf.now - start_time
          total_count = result.stats.sum { |stat| stat[:total_count] }
          total_top_level_count = result.stats.sum { |stat| stat[:top_level_count] }
          total_time = result.stats.sum { |stat| stat[:top_level_time] }
          total_uniq_factories = result.stats.map { |stat| stat[:name] }.uniq.count

          msgs <<
            <<~MSG
              Factories usage

               Total: #{total_count}
               Total top-level: #{total_top_level_count}
               Total time: #{total_time.duration} (out of #{total_run_time.duration})
               Total uniq factories: #{total_uniq_factories}

                 name                    total   top-level     total time      time per call      top-level time
            MSG

          result.stats.each do |stat|
            next if stat[:total_count] < threshold

            msgs << format("%-3s%-20s %8d %11d %13.4fs %17.4fs %18.4fs", *format_args(stat))
            # move other variation ("[...]") to the end of the array
            sorted_variations = stat[:variations].sort_by.with_index do |variation, i|
              (variation[:name] == "[...]") ? stat[:variations].size + 1 : i
            end
            sorted_variations.each do |variation_stat|
              msgs << format("%-5s%-18s %8d %11d %13.4fs %17.4fs %18.4fs", *format_args(variation_stat))
            end
          end

          log :info, msgs.join("\n")
        end

        private

        def format_args(stat)
          time_per_call = stat[:total_time] / stat[:total_count]
          format_args = [""]
          format_args += stat.values_at(:name, :total_count, :top_level_count, :total_time)
          format_args << time_per_call
          format_args << stat[:top_level_time]
        end
      end
    end
  end
end
