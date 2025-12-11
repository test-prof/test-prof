# frozen_string_literal: true

require "rubocop"
require "rubocop/test_prof/plugin"
require "rubocop/rspec/support"

RSpec.configure do |config|
  config.include(RuboCop::RSpec::ExpectOffense)
end
