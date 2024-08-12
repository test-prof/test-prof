# frozen_string_literal: true

require "active_record"

shared_context "transactional", transactional: true do
  prepend_before(:each) do
    ActiveRecord::Base.connection.begin_transaction(joinable: false)
    ::Isolator.incr_thresholds! if defined?(::Isolator)
  end

  append_after(:each) do
    ::Isolator.decr_thresholds! if defined?(::Isolator)
    ActiveRecord::Base.connection.rollback_transaction unless
      ActiveRecord::Base.connection.open_transactions.zero?
  end
end
