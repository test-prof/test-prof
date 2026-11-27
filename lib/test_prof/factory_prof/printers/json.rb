# frozen_string_literal: true

require "test_prof/printers/json"

module TestProf::FactoryProf
  module Printers
    module Json  # :nodoc: all
      class << self
        include TestProf::Logging
        include TestProf::Printers::Json

        def dump(result, start_time:, **)
          return log(:info, "No factories detected") if result.raw_stats == {}

          dump_json("factory_prof", convert_stats(result, start_time), filename: "test-prof.result.json")
        end

        def convert_stats(result, start_time)
          total_run_time = TestProf.now - start_time
          total_count = result.stats.sum { |stat| stat[:total_count] }
          total_top_level_count = result.stats.sum { |stat| stat[:top_level_count] }
          total_time = result.stats.sum { |stat| stat[:top_level_time] }
          total_uniq_factories = result.stats.map { |stat| stat[:name] }.uniq.count

          {
            total_count: total_count,
            total_top_level_count: total_top_level_count,
            total_time: total_time,
            total_run_time: total_run_time,
            total_uniq_factories: total_uniq_factories,

            stats: result.stats
          }
        end
      end
    end
  end
end
