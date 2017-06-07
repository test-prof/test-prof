# frozen_string_literal: true

require "spec_helper"

describe "BeforeAll spec" do
  specify "it works" do
    output = run_rspec('before_all_rspec_fixture.rb')

    expect(output).to include("3 examples, 0 failures")
  end
end
