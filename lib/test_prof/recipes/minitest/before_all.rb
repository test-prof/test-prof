# frozen_string_literal: true

require "test_prof/before_all"

module TestProf
  module BeforeAll
    # Add before_all hook to Minitest: wrap all examples into a transaction and
    # store instance variables
    module Minitest # :nodoc: all
      class Executor
        attr_reader :active

        alias active? active

        def initialize(&block)
          @block = block
        end

        def activate!(test_class)
          return if active?
          @active = true
          @examples_left = test_class.runnable_methods.size
          BeforeAll.begin_transaction
          capture!
        end

        def try_deactivate!
          @examples_left -= 1
          return unless @examples_left.zero?

          @active = false
          BeforeAll.rollback_transaction
        end

        def capture!
          instance_eval(&@block)
        end

        def restore_to(test_object)
          instance_variables.each do |ivar|
            next if ivar == :@block
            test_object.instance_variable_set(
              ivar,
              instance_variable_get(ivar)
            )
          end
        end
      end

      class << self
        def included(base)
          base.extend ClassMethods
        end
      end

      module ClassMethods
        attr_accessor :before_all_executor

        def before_all(&block)
          self.before_all_executor = Executor.new(&block)

          prepend(Module.new do
            def setup
              self.class.before_all_executor.activate!(self.class)
              self.class.before_all_executor.restore_to(self)
              super
            end

            def teardown
              super
              self.class.before_all_executor.try_deactivate!
            end
          end)
        end
      end
    end
  end
end
