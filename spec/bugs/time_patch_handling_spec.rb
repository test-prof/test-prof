# frozen_string_literal: true

require "spec_helper"

# https://github.com/palkan/test-prof/issues/10
describe "Time.now patching handling (e.g. Timecop)", type: :integration do
  specify "works with ad-hoc patch" do
    output = run_rspec(
      'time_patch',
      chdir: File.join(__dir__, "fixtures"),
      env: { 'TAG_PROF' => 'a' }
    )

    matches = output.match(/x\s+\d{2}\:(\d{2})\.(\d{3})\s+/)
    s, ms = matches[1].to_i, matches[2].to_i

    expect(s + ms).to be > 0
  end

  specify "works with timecop" do
    output = run_rspec(
      'timecop',
      chdir: File.join(__dir__, "fixtures"),
      env: { 'TAG_PROF' => 'a' }
    )

    matches = output.match(/x\s+\d{2}\:(\d{2})\.(\d{3})\s+/)
    s, ms = matches[1].to_i, matches[2].to_i

    expect(s + ms).to be > 0
  end
end
