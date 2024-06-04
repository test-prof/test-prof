# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require "timecop" if ENV.fetch("TIMECOP_ORDER", "before") == "before"
require "test-prof"
require "timecop" if ENV.fetch("TIMECOP_ORDER", "before") == "after"

Timecop.freeze

describe "Something" do
  it "sleeps a little", a: :x do
    sleep 0.1
    expect(true).to eq true
  end
end
