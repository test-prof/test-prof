# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require "minitest/autorun"
require "active_support"
require "test-prof"

TestProf::EventProf.configure do |config|
  config.per_example = true
end

module Instrumenter
  def self.notify(_event, time)
    sleep 0.1
    ActiveSupport::Notifications.publish(
      "test.event",
      0,
      time
    )
  end
end

describe "Something" do
  it "invokes once" do
    Instrumenter.notify "test.event", 0.0401
    assert true
  end

  it "invokes twice" do
    Instrumenter.notify "test.event", 0.014
    Instrumenter.notify "test.event", 0.024
    assert true
  end

  it "invokes many times" do
    Instrumenter.notify "test.event", 0.014
    Instrumenter.notify "test.event", 0.04
    Instrumenter.notify "test.event", 0.042
    Instrumenter.notify "test.event", 0.04
    assert true
  end
end

describe "Another something" do
  it "do nothing" do
    assert true
  end

  it "do very long and invokes 3 times" do
    Instrumenter.notify "test.event", 0.1
    Instrumenter.notify "test.event", 0.1
    Instrumenter.notify "test.event", 0.1
    assert true
  end
end
