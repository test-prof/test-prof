# frozen_string_literal: true

require "test_prof/any_fixture"

RSpec.shared_context "any_fixture:clean", with_clean_fixture: true do
  before do
    raise("Cannot use clean context without a transaction!") unless
      open_transaction?

    TestProf::AnyFixture.clean
  end

  def open_transaction?
    pool = ActiveRecord::Base.connection_pool
    pool.active_connection? && pool.connection.open_transactions > 0
  end
end

RSpec.configure do |config|
  config.after(:suite) { TestProf::AnyFixture.reset }
end
