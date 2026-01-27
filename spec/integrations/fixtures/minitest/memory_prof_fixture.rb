# frozen_string_literal: true

require "minitest/autorun"
require "test-prof"
Minitest.load :test_prof if Minitest.respond_to?(:load)

require "securerandom"

describe "First Allocations" do
  it "allocates 500 objects" do
    500.times.map { SecureRandom.hex }
  end

  it "allocates 1000 objects" do
    1000.times.map { SecureRandom.hex }
  end

  it "allocates 10_000 objects" do
    10_000.times.map { SecureRandom.hex }
  end
end

describe "Second Allocations" do
  it "allocates nothing" do
  end

  it "allocates 100 objects" do
    100.times.map { SecureRandom.hex }
  end
end
