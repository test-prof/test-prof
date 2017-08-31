# frozen_string_literal: true

module TestProf
  module Utils
    # Ordered set with capacity
    class SizedOrderedSet
      unless [].respond_to?(:bsearch_index)
        require "test_prof/ext/array_bsearch_index"
        using ArrayBSearchIndex
      end

      include Enumerable

      def initialize(max_size, sort_by: nil)
        @max_size = max_size
        @comparator =
          if block_given?
            Proc.new
          elsif !sort_by.nil?
            ->(x, y) { x[sort_by] >= y[sort_by] }
          else
            ->(x, y) { x >= y }
          end
        @data = []
      end

      def <<(item)
        return if data.size == max_size &&
                  comparator.call(data.last, item)

        # Find an index of a smaller element
        index = data.bsearch_index { |x| !comparator.call(x, item) }

        if index.nil?
          data << item
        else
          data.insert(index, item)
        end

        data.pop if data.size > max_size
        data.size
      end

      def each
        if block_given?
          data.each(&Proc.new)
        else
          data.each
        end
      end

      def size
        data.size
      end

      def to_a
        data.dup
      end

      private

      attr_reader :max_size, :data, :comparator
    end
  end
end
