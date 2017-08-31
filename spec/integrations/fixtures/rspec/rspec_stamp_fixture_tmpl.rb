# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require "active_support"
require "test-prof"

shared_context "fixxer", fix: :me do
  before { @value = true }
end

describe "Something" do
  it "fail me" do
    expect(@value).to eq true
  end

  it "fail me with tag", fix: :no do
    expect(@value).to eq true
  end

  it "always passes" do
    expect(true).to eq true
  end

  specify '
    you
    can
    not
    patch me
  ' do
    expect(@value).to eq true
  end

  context "nested context" do
    subject { @value }
    specify { is_expected.to eq true }
  end
end
