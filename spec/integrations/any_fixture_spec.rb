# frozen_string_literal: true

require "spec_helper"

describe "AnyFixture" do
  specify "it works" do
    output = run_rspec('any_fixture')

    expect(output).to include("3 examples, 0 failures")
  end
end
