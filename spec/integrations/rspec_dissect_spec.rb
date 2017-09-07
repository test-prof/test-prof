# frozen_string_literal: true

require "spec_helper"

describe "RSpecDissect" do
  specify "it works", :aggregate_failures do
    output = run_rspec('rspec_dissect', env: { 'RD_PROF' => '1' })

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
    output = run_rspec('rspec_dissect', env: { 'RD_PROF' => '1', 'RD_PROF_TOP' => '1' })

    expect(output).to include("5 examples, 0 failures")

    expect(output).to include_lines(
      "Top 1 slowest suites (by `before(:each)` time):",
      "Subject + Before (./rspec_dissect_fixture.rb:22) – ",
      "Top 1 slowest suites (by `let` time):",
      "Only let (./rspec_dissect_fixture.rb:42) – "
    )
  end

  context "with RStamp" do
    before do
      FileUtils.cp(
        File.expand_path("../../integrations/fixtures/rspec/rspec_dissect_stamp_fixture_tmpl.rb", __FILE__),
        File.expand_path("../../integrations/fixtures/rspec/rspec_dissect_stamp_fixture.rb", __FILE__)
      )
    end

    after do
      FileUtils.rm(
        File.expand_path("../../integrations/fixtures/rspec/rspec_dissect_stamp_fixture.rb", __FILE__)
      )
    end

    specify "it works", :aggregate_failures do
      output = run_rspec(
        'rspec_dissect_stamp',
        env: { 'RD_PROF' => '1', 'RD_PROF_STAMP' => 'slow', 'RD_PROF_TOP' => '1' }
      )

      expect(output).to include("5 examples, 0 failures")

      expect(output).to include_lines(
        "Top 1 slowest suites (by `before(:each)` time):",
        "Subject + Before (./rspec_dissect_stamp_fixture.rb:22) – "
      )

      expect(output).to include("RSpec Stamp results")
      expect(output).to include("Total patches: 1")
      expect(output).to include("Total files: 1")
      expect(output).to include("Failed patches: 0")
      expect(output).to include("Ignored files: 0")

      output2 = run_rspec(
        'rspec_dissect_stamp',
        env: { 'SPEC_OPTS' => '--tag slow' }
      )

      expect(output2).to include("3 examples, 0 failures")
    end
  end
end
