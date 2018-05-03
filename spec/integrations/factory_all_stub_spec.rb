# frozen_string_literal: true

require "spec_helper"

describe "FactoryAllStub" do
  specify "it works" do
    output = run_rspec('factory_all_stub')

    expect(output).to include("3 examples, 0 failures")
  end
end
