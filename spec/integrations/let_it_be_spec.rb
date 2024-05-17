# frozen_string_literal: true

describe "LetItBe" do
  specify "it works" do
    output = run_rspec("let_it_be")

    expect(output).to include("0 failures")
  end

  specify "default and metadata modifiers" do
    output = run_rspec("let_it_be_modifiers")

    expect(output).to include("0 failures")
  end

  specify "it detects state leakages" do
    output = run_rspec("let_it_be_modification_detection")

    expect(output).to include("0 failures")
  end

  specify "it detects let_it_be override" do
    output = run_rspec("let_it_be_nested")

    expect(output).to include("0 failures")
  end
end
