# frozen_string_literal: true

require "active_record"

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
