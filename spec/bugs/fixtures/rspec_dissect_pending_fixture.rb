# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require "test-prof"

describe "Something" do
  it "works" do
    expect(true).to eq true
  end

  it "is pending", :pending do
    expect(true).to eq false
  end

  xit "is skipped" do
    expect(true).to eq false
  end
end
