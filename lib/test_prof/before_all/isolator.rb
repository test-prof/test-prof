# frozen_string_literal: true

module TestProf
  module BeforeAll
    # Disable Isolator within before_all blocks
    module Isolator
      def begin_transaction(*)
        ::Isolator.disable { super }
      end

      def within_transaction(*)
        ::Isolator.disable { super }
      end
    end
  end
end

TestProf::BeforeAll.singleton_class.prepend(TestProf::BeforeAll::Isolator)
