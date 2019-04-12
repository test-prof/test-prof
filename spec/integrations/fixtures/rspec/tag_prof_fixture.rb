# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require "test-prof"

TestProf.configure do |config|
  config.output_dir = "../../../../tmp"
end

module Instrumenter
  def self.notify(event = "test.event", time)
    ActiveSupport::Notifications.publish(
      event,
      0,
      time
    )
  end
end

describe "Something" do
  it "fail me", type: :fail do
    Instrumenter.notify "test.event", 23
    expect(@value).to be_nil
  end

  it "always passes", type: :pass do
    Instrumenter.notify "test.event", 2.4202
    Instrumenter.notify "test.event2", 14.0411
    expect(true).to eq true
  end

  specify do
    @value = true
    expect(@value).to eq true
  end

  context "nested context", type: :pass do
    before { @value = true }
    subject { @value }
    specify do
      Instrumenter.notify "test.event", 10
      is_expected.to eq true
    end
  end
end
