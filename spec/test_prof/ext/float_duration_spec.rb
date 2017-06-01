# frozen_string_literal: true

require "spec_helper"
require "test_prof/ext/float_duration"

using TestProf::FloatDuration

describe TestProf::FloatDuration do
  it "works" do
    expect((27 * 60 + 41.05142).duration).to eq "27:41.051"
  end
end
