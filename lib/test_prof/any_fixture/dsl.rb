# frozen_string_literal: true

module TestProf
  module AnyFixture
    # Adds "global" `fixture` method (through refinement)
    module DSL
      refine Kernel do
        def fixture(id, &block)
          ::TestProf::AnyFixture.register(:"#{id}", &block)
        end
      end
    end
  end
end
