# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require "test-prof"

TestProf.configure do |config|
  config.output_dir = "../../../../tmp/test_prof"
end

describe "dummy" do
  it "always passes" do
    expect(true).to eq true
  end
end
