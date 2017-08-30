# frozen_string_literal: true

module TestProf
  # Add #strip_heredoc method to use instead of
  # squiggly docs (to support older Rubies)
  module StringStripHeredoc
    refine String do
      def strip_heredoc
        min = scan(/^[ \t]*(?=\S)/).min
        indent = min ? min.size : 0
        gsub(/^[ \t]{#{indent}}/, '')
      end
    end
  end
end
