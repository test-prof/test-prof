# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require "active_support"
require "test-prof"

describe "Something" do
  it "sleeps a bit" do
    sleep 0.12
    expect(true).to eq true
  end

  it "sleeps a bit more" do
    sleep 0.43
    expect(true).to eq true
  end
end

describe "Another something" do
  before(:all) { sleep 1.3 }

  it "do nothing" do
    expect(true).to eq true
  end

  it "sleeps too long" do
    sleep 1.2
    expect(true).to eq true
  end
end
