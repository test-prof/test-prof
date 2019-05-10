# frozen_string_literal: true

module TestProf::FactoryProf
  module Printers
    module Simple # :nodoc: all
      class << self
        include TestProf::Logging

        def dump(result)
          return log(:info, "No factories detected") if result.raw_stats == {}
          msgs = []

          total_count = result.stats.sum { |stat| stat[:total_count] }
          total_top_level_count = result.stats.sum { |stat| stat[:top_level_count] }
          total_time = result.stats.sum { |stat| stat[:top_level_time] }
          total_uniq_factories = result.stats.map { |stat| stat[:name] }.uniq.count

          msgs <<
            <<~MSG
              Factories usage

               Total: #{total_count}
               Total top-level: #{total_top_level_count}
               Total time: #{format("%.4f", total_time)}s
               Total uniq factories: #{total_uniq_factories}

                 total   top-level   total time   top-level time                           name
            MSG

          result.stats.each do |stat|
            msgs << format("%8d %11d %11.4fs %15.4fs %30s", stat[:total_count], stat[:top_level_count], stat[:total_time], stat[:top_level_time], stat[:name])
          end

          log :info, msgs.join("\n")
        end
      end
    end
  end
end
