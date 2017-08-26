# frozen_string_literal: true

require "spec_helper"
require "test_prof/ext/string_truncate"

using TestProf::StringTruncate

describe TestProf::StringTruncate do
  it "doesn't modify if less than limit", :aggregate_failures do
    expect("abc".truncate).to eq "abc"
    expect("abcdefgh".truncate(10)).to eq "abcdefgh"
  end

  it "has default limit of 30" do
    expect((("a".."z").to_a.join * 2).truncate).to eq "abcdefghijklm...mnopqrstuvwxyz"
  end

  it "works with custom length", :aggregate_failures do
    expect("abcdefgh".truncate(5)).to eq "a...h"
    expect("abcdef".truncate(5)).to eq "a...f"
  end
end
