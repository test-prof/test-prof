# frozen_string_literal: true

describe "FactoryAllStub" do
  specify "it works" do
    output = run_rspec("factory_all_stub")

    expect(output).to include("0 failures")
  end
end
