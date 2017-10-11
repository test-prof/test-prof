# frozen_string_literal: true

require "test_prof/ext/string_strip_heredoc"

module TestProf::FactoryProf
  module Printers
    module Simple # :nodoc: all
      class << self
        include TestProf::Logging
        using TestProf::StringStripHeredoc

        def dump(result)
          return log(:info, "No factories detected") if result.raw_stats == {}
          msgs = []

          msgs <<
            <<-MSG.strip_heredoc
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
