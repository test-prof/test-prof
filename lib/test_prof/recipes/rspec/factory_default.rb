# frozen_string_literal: true

require "test_prof/factory_default"

TestProf::FactoryDefault.init

RSpec.configure do |config|
  config.after(:each) { TestProf::FactoryDefault.reset }
end
