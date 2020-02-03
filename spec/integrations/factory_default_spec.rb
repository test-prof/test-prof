# frozen_string_literal: true

describe "FactoryDefault" do
  specify "RSpec integration", :aggregate_failures do
    output = run_rspec("factory_default")

    expect(output).to include("0 failures")
  end
end
