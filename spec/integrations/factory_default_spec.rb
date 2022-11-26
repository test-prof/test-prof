# frozen_string_literal: true

describe "FactoryDefault" do
  specify "RSpec integration", :aggregate_failures do
    output = run_rspec("factory_default")

    expect(output).to include("0 failures")
  end

  specify "let_it_be integration", :aggregate_failures do
    output = run_rspec("factory_default_let_it_be")

    expect(output).to include("0 failures")
  end
end
