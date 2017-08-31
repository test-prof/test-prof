# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require "test_prof/recipes/rspec/sample"

describe "Something" do
  it "always passes" do
    expect(true).to eq true
  end
end

describe "One more thing" do
  it "always passes" do
    expect(true).to eq true
  end
end

describe "One more light" do
  it "flickers" do
    expect(true).to eq true
  end
end
