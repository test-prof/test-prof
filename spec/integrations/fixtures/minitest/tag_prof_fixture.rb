# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require "minitest/autorun"
Minitest.load :test_prof if Minitest.respond_to?(:load)

require "active_support"
require "test-prof"

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

describe "Test Class" do
  it "succeeds" do
    Instrumenter.notify "test.event", 100
    assert(true)
  end
end
