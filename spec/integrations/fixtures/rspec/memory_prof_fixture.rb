# frozen_string_literal: true

require "test-prof"
require "securerandom"

describe "Examples allocations" do
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

describe "Groups Allocations" do
  context "with 500 allocations" do
    before(:context) do
      @array = 500.times.map { SecureRandom.hex }
    end

    it { 1 }
  end

  context "with 1000 allocations" do
    before(:context) do
      @array = 1000.times.map { SecureRandom.hex }
    end

    it "does not allocate anything" do
    end
  end

  context "with 10_000 allocations" do
    before(:context) do
      @array = 10_000.times.map { SecureRandom.hex }
    end

    it "does not allocate anything" do
    end
  end
end
