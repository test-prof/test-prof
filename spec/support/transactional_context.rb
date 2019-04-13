# frozen_string_literal: true

require "active_record"

if ActiveRecord::VERSION::MAJOR < 4
  require "test_prof/ext/active_record_3"
  using TestProf::ActiveRecord3Transactions
end

shared_context "transactional", transactional: true do
  prepend_before(:each) do
    ActiveRecord::Base.connection.begin_transaction(joinable: false)
    Isolator.transactions_threshold += 1 if defined?(Isolator)
  end

  append_after(:each) do
    Isolator.transactions_threshold -= 1 if defined?(Isolator)
    ActiveRecord::Base.connection.rollback_transaction
  end
end
