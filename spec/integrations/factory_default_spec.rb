# frozen_string_literal: true

require "spec_helper"

describe "FactoryDefault" do
  specify "RSpec integration", :aggregate_failures do
    output = run_rspec("factory_default")

    expect(output).to include("8 examples, 0 failures")
  end
end
