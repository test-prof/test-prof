# frozen_string_literal: true

module TestProf
  # Ruby 2.3 #bsearch_index method (for usage with older Rubies)
  # Straighforward and non-optimal implementation,
  # just for compatiblity
  module ArrayBSearchIndex
    refine Array do
      def bsearch_index(&block)
        el = bsearch(&block)
        index(el)
      end
    end
  end
end
