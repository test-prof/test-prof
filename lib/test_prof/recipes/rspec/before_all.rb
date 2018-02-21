# frozen_string_literal: true

if ActiveRecord::VERSION::MAJOR < 4
  require "test_prof/ext/active_record_3"
  using TestProf::ActiveRecord3Transactions
end

module TestProf
  # Helper to wrap the whole example group into a transaction
  module BeforeAll
    def before_all(&block)
      raise ArgumentError, "Block is required!" unless block_given?

      return before(:all, &block) if within_before_all?

      @__before_all_activated__ = true

      before(:all) do
        ActiveRecord::Base.connection.begin_transaction(joinable: false)
        instance_eval(&block)
      end

      after(:all) do
        ActiveRecord::Base.connection.rollback_transaction
      end
    end

    def within_before_all?
      instance_variable_defined?(:@__before_all_activated__)
    end
  end
end

RSpec.configure do |config|
  config.extend TestProf::BeforeAll
end
