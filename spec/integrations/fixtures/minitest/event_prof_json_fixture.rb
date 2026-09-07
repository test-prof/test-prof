# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require "minitest/autorun"
Minitest.load :test_prof if Minitest.respond_to?(:load)

require "active_support"
require "test-prof"

TestProf.configure do |config|
  config.output_dir = "../../../../tmp/test_prof"
end

TestProf::EventProf.configure do |config|
  config.per_example = true
end

module Instrumenter
  def self.notify(_event, time)
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
end
