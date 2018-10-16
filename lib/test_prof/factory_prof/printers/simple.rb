# frozen_string_literal: true

module TestProf::FactoryProf
  module Printers
    module Simple # :nodoc: all
      class << self
        include TestProf::Logging

        def dump(result)
          return log(:info, "No factories detected") if result.raw_stats == {}
          msgs = []

          total = result.stats.inject(0) { |acc, stat| acc += stat[:total] }
          total_top_level = result.stats.inject(0) { |acc, stat| acc += stat[:top_level] }
          total_uniq_factories = result.stats.map { |stat| stat[:name] }.uniq.count

          msgs <<
            <<~MSG
              Factories usage

               Total: #{total}
               Total top-level: #{total_top_level}
               Total uniq factories: #{total_uniq_factories}

               total      top-level                            name
            MSG

          result.stats.each do |stat|
            msgs << format("%6d    %11d  %30s", stat[:total], stat[:top_level], stat[:name])
          end

          log :info, msgs.join("\n")
        end
      end
    end
  end
end
