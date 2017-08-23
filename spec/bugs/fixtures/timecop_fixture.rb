# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require "timecop"
require "test-prof"

Timecop.freeze

describe "Something" do
  it "sleeps a little", a: :x do
    sleep 0.1
    expect(true).to eq true
  end
end
