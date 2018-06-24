# frozen_string_literal: true

require "test_prof/before_all"

module TestProf
  module BeforeAll
    # Helper to wrap the whole example group into a transaction
    module RSpec
      def before_all(&block)
        raise ArgumentError, "Block is required!" unless block_given?

        return before(:all, &block) if within_before_all?

        @__before_all_activated__ = true

        before(:all) do
          BeforeAll.begin_transaction
          instance_eval(&block)
        end

        after(:all) do
          BeforeAll.rollback_transaction
        end
      end

      def within_before_all?
        instance_variable_defined?(:@__before_all_activated__)
      end
    end
  end
end

RSpec.configure do |config|
  config.extend TestProf::BeforeAll::RSpec
end
