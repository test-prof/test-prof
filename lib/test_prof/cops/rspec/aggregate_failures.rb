# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      class AggregateExamples
        def self.inherited(subclass)
          superclass.registry.enlist(subclass)
        end
      end

      class AggregateFailures < AggregateExamples
        def initialize(*)
          super
          self.class.just_once { warn "`AggregateFailures` cop has been renamed to `AggregateExamples`." }
        end

        def self.just_once
          return if @already_done
          yield
          @already_done = true
        end
      end
    end
  end
end
