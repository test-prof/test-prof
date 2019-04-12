# frozen_string_literal: true

require "spec_helper"

# https://github.com/palkan/test-prof/issues/60
describe "RSpecDissect with pending examples", type: :integration do
  specify do
    output = run_rspec(
      "rspec_dissect_pending",
      chdir: File.join(__dir__, "fixtures"),
      env: {"RD_PROF" => "1"}
    )

    expect(output).to include("3 examples, 0 failures, 2 pending")
    expect(output).to include("RSpecDissect report")
  end
end
