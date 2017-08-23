# frozen_string_literal: true

require "spec_helper"

describe "RSpecStamp" do
  before do
    FileUtils.cp(
      File.expand_path("../../integrations/fixtures/rspec/rspec_stamp_fixture_tmpl.rb", __FILE__),
      File.expand_path("../../integrations/fixtures/rspec/rspec_stamp_fixture.rb", __FILE__)
    )
  end

  after do
    FileUtils.rm(
      File.expand_path("../../integrations/fixtures/rspec/rspec_stamp_fixture.rb", __FILE__)
    )
  end

  specify "it works", :aggregate_failures do
    output = run_rspec('rspec_stamp', success: false, env: { 'RSTAMP' => 'fix:me' })

    expect(output).to include("5 examples, 4 failures")

    expect(output).to include("RSpec Stamp results")
    expect(output).to include("Total patches: 4")
    expect(output).to include("Total files: 1")
    expect(output).to include("Failed patches: 1")
    expect(output).to include("Ignored files: 0")

    output2 = run_rspec('rspec_stamp', success: false)

    expect(output2).to include("5 examples, 1 failure")
  end

  specify "it works with dry-run", :aggregate_failures do
    output = run_rspec('rspec_stamp', success: false, env: { 'RSTAMP' => 'fix:me', 'RSTAMP_DRY_RUN' => '1' })

    expect(output).to include("5 examples, 4 failures")

    expect(output).to include("RSpec Stamp results")
    expect(output).to include("Total patches: 4")
    expect(output).to include("Total files: 1")
    expect(output).to include("Failed patches: 1")
    expect(output).to include("Ignored files: 0")

    expect(output).to include("(dry-run) Patching ./rspec_stamp_fixture.rb")
    expect(output).to include("Patched:   it 'fail me', fix: :me do")
    expect(output).to include("Patched:   it 'fail me with tag', fix: :me do")

    output2 = run_rspec('rspec_stamp', success: false)

    expect(output2).to include("5 examples, 4 failures")
  end
end
