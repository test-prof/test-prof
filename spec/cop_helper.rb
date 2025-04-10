# frozen_string_literal: true

require "rubocop"
require "test_prof/cops/plugin"
require "rubocop/rspec/support"

RSpec.configure do |config|
  config.include(RuboCop::RSpec::ExpectOffense)
end
