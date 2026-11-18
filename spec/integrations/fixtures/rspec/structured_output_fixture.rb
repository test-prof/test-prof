# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require "test-prof"

TestProf.configure do |config|
  config.output_dir = "../../../../tmp/test_prof"
end

describe "Something" do
  let(:value) { "value" }

  before { @value = value }

  it "works" do
    expect(@value).to eq "value"
  end

  it "works again" do
    expect(value).to eq "value"
  end
end
