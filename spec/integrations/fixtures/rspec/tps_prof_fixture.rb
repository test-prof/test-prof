# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require "active_support"
require "test-prof"

if ENV["CUSTOM_STRICT_HANDLER"] == "1"
  TestProf::TPSProf.configure do |config|
    config.strict_handler = proc do |group_info|
      raise "I don't like this example group: #{group_info.location}" if group_info.tps < 4
    end
  end
end

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

describe "Slow known", tps_prof: :ignore do
  it "sleeps a lot" do
    sleep 1.4
    expect(true).to eq true
  end

  it "sleeps too" do
    sleep 1.1
    expect(false).to eq false
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
