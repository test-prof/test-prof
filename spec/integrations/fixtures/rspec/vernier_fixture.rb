# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require "test-prof"

TestProf.configure do |config|
  config.output_dir = "../../../../tmp/test_prof"
end

shared_examples_for "Something" do
  it "always passes", :vernier do
    expect(true).to eq true
  end
end

describe "One more thing" do
  include_examples "Something"
end
