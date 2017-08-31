# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require "test-prof"

describe "Something" do
  it "fail me", type: :fail do
    expect(@value).to be_nil
  end

  it "always passes", type: :pass do
    expect(true).to eq true
  end

  specify do
    @value = true
    expect(@value).to eq true
  end

  context "nested context", type: :pass do
    before { @value = true }
    subject { @value }
    specify { is_expected.to eq true }
  end
end
