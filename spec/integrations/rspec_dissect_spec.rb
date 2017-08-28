# frozen_string_literal: true

require "spec_helper"

describe "RSpecDissect" do
  specify "it works", :aggregate_failures do
    output = run_rspec('rspec_dissect', env: { 'RD' => '1' })

    expect(output).to include("5 examples, 0 failures")

    expect(output).to include("RSpecDissect report")
    expect(output).to match(/Total time:\s+\d{2}:\d{2}\.\d{3}/)
    expect(output).to match(/Total `before\(:each\)` time:\s+\d{2}:\d{2}\.\d{3}/)
    expect(output).to match(/Total `let` time:\s+\d{2}:\d{2}\.\d{3}/)

    expect(output).to include_lines(
      "Top 5 slowest suites (by `before(:each)` time):",
      "Subject + Before (./rspec_dissect_fixture.rb:22) – ",
      "Only let (./rspec_dissect_fixture.rb:42) – ",
      "Top 5 slowest suites (by `let` time):",
      "Only let (./rspec_dissect_fixture.rb:42) – ",
      "Subject + Before (./rspec_dissect_fixture.rb:22) – "
    )
  end

  specify "it works with specified top count", :aggregate_failures do
    output = run_rspec('rspec_dissect', env: { 'RD' => '1', 'RD_TOP' => '1' })

    expect(output).to include("5 examples, 0 failures")

    expect(output).to include_lines(
      "Top 1 slowest suites (by `before(:each)` time):",
      "Subject + Before (./rspec_dissect_fixture.rb:22) – ",
      "Top 1 slowest suites (by `let` time):",
      "Only let (./rspec_dissect_fixture.rb:42) – "
    )
  end
end
