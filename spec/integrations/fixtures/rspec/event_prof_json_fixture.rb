# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require "active_support"
require "test-prof"

TestProf.configure do |config|
  config.output_dir = "../../../../tmp/test_prof"
end

TestProf::EventProf.configure do |config|
  config.per_example = true
end

module Instrumenter
  def self.notify(event = "test.event", time = 0)
    ActiveSupport::Notifications.publish(
      event,
      0,
      time
    )
  end
end

describe "Something" do
  it "invokes once" do
    Instrumenter.notify "test.event", 0.0401
    expect(true).to eq true
  end

  it "invokes twice" do
    Instrumenter.notify "test.event", 0.014
    Instrumenter.notify "test.event", 0.024
    expect(true).to eq true
  end
end

describe "Another something" do
  it "do very long" do
    Instrumenter.notify "test.event", 0.145
    expect(true).to eq true
  end
end
