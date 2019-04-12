# frozen_string_literal: true

require "test_prof/any_fixture"
require "test_prof/recipes/rspec/before_all"

RSpec.shared_context "any_fixture:clean", with_clean_fixture: true do
  extend TestProf::BeforeAll::RSpec

  before_all do
    TestProf::AnyFixture.clean
  end
end

RSpec.configure do |config|
  if defined?(config.include_context)
    config.include_context "any_fixture:clean", with_clean_fixture: true
  end

  config.after(:suite) do
    TestProf::AnyFixture.report_stats if TestProf::AnyFixture.reporting_enabled?
    TestProf::AnyFixture.reset
  end
end
