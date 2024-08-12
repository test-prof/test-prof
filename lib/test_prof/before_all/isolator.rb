# frozen_string_literal: true

TestProf::BeforeAll.configure do |config|
  config.before(:begin) do
    ::Isolator.incr_thresholds!
  end

  config.after(:rollback) do
    ::Isolator.decr_thresholds!
  end
end
