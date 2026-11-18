# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require "minitest/autorun"
Minitest.load :test_prof if Minitest.respond_to?(:load)

require "test-prof"

TestProf.configure do |config|
  config.output_dir = "../../../../tmp/test_prof"
end

describe "Test Class" do
  it "succeeds" do
    assert(true)
  end
end
