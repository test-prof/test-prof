# frozen_string_literal: true

require "spec_helper"

describe "BeforeAll" do
  specify "it works" do
    output = run_rspec('before_all')

    expect(output).to include("8 examples, 0 failures")
  end
end
