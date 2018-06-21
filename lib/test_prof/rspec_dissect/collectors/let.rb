# frozen_string_literal: true

require_relative "./base"

module TestProf
  module RSpecDissect
    module Collectors # :nodoc: all
      class Let < Base
        def initialize(params)
          super(name: :let, **params)
        end

        def print_results
          return unless RSpecDissect.memoization_available?
          super
        end
      end
    end
  end
end
