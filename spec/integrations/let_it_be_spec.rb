# frozen_string_literal: true

describe "LetItBe" do
  specify "it works" do
    output = run_rspec("let_it_be")

    expect(output).to include("0 failures")
  end
end
