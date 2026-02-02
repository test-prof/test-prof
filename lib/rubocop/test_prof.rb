# frozen_string_literal: true

if Gem::Version.new(RuboCop::Version::STRING) < Gem::Version.new("0.51.0")
  warn "TestProf cops require RuboCop >= 0.51.0 to run."
  return
end

require "rubocop/test_prof/plugin"
require "rubocop/test_prof/cops/rspec/aggregate_examples"
