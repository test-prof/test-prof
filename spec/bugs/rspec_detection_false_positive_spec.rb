# frozen_string_literal: true

# https://github.com/palkan/test-prof/issues/8
describe "RSpec false positive detection", type: :integration do
  specify do
    output = run_minitest("rspec_detection_false_positive", chdir: File.join(__dir__, "fixtures"))

    expect(output).to include("1 runs, 1 assertions, 0 failures, 0 errors, 0 skips")
  end
end
