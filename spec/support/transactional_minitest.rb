# frozen_string_literal: true

require "active_record"

if ActiveRecord::VERSION::MAJOR < 4
  require "test_prof/ext/active_record_3"
  using TestProf::ActiveRecord3Transactions
end

module TransactionalMinitest
  def setup
    ActiveRecord::Base.connection.begin_transaction(joinable: false)
    super
  end

  def teardown
    super
    ActiveRecord::Base.connection.rollback_transaction
  end
end
