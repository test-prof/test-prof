# frozen_string_literal: true

require "spec_helper"

describe "LetItBe" do
  specify "it works" do
    output = run_rspec('let_it_be')

    expect(output).to include("18 examples, 0 failures")
  end
end
