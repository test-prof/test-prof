# frozen_string_literal: true

require "spec_helper"

describe "AnyFixture" do
  specify "it works" do
    output = run_rspec("any_fixture")
    expect(output).to include("0 failures")
  end

  specify "with usage report enabled" do
    output = run_rspec("any_fixture", env: {"ANYFIXTURE_REPORT" => "1"})

    expect(output).to include("AnyFixture usage stats:")
    expect(output).to match(/key\s+build time\s+hit count\s+saved time\n\n/)
    expect(output).to match(/user\s+\d{2}\:\d{2}\.\d{3}\s+4\s+\d{2}\:\d{2}\.\d{3}/)
    expect(output).to match(/post\s+\d{2}\:\d{2}\.\d{3}\s+1\s+\d{2}\:\d{2}\.\d{3}/)
    expect(output).to include("0 failures")
  end
end
