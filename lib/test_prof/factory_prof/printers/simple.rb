# frozen_string_literal: true

module TestProf::FactoryProf
  module Printers
    module Simple # :nodoc: all
      class << self
        include TestProf::Logging

        def dump(result)
          msgs = []

          msgs <<
            <<~MSG
              Factories usage

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
