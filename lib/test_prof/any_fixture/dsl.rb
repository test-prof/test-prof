# frozen_string_literal: true

module TestProf
  module AnyFixture
    # Adds "global" `fixture` method (through refinement)
    module DSL
      module Ext # :nodoc:
        def fixture(id, &block)
          ::TestProf::AnyFixture.register(:"#{id}", &block)
        end
      end

      refine Kernel do
        include Ext
      end
    end
  end
end
