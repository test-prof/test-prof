# frozen_string_literal: true

require "spec_helper"

describe "Tests Sampling" do
  context "RSpec integration" do
    specify "SAMPLE=2" do
      output = run_rspec('sample', env: { 'SAMPLE' => '2' })

      expect(output).to include("2 examples, 0 failures")
    end

    specify "SAMPLE=1" do
      output = run_rspec('sample', env: { 'SAMPLE' => '1' })

      expect(output).to include("1 example, 0 failures")
    end

    specify "SAMPLE=1 with tag filter" do
      output = run_rspec('sample', env: { 'SAMPLE' => '1' }, options: "-fd --tag sometag")

      expect(output).to include("always passes with tag")
      expect(output).to include("1 example, 0 failures")
    end

    specify "SAMPLE=1 with description filter" do
      output = run_rspec('sample', env: { 'SAMPLE' => '1' }, options: "-fd -e flickers")

      expect(output).to include("flickers")
      expect(output).to include("1 example, 0 failures")
    end

    specify "GROUP_SAMPLE=1" do
      output = run_rspec('sample', env: { 'GROUP_SAMPLE' => '1' })

      expect(output).to include("1 example, 0 failures")
    end

    specify "GROUP_SAMPLE=2" do
      output = run_rspec('sample', env: { 'GROUP_SAMPLE' => '2' })

      expect(output).to include("2 examples, 0 failures")
    end
  end

  context "Minitest integration" do
    specify "SAMPLE=2" do
      output = run_minitest('sample', env: { 'SAMPLE' => '2' })

      expect(output).to include("2 runs, 2 assertions, 0 failures, 0 errors, 0 skips")
    end

    specify "SAMPLE=1" do
      output = run_minitest('sample', env: { 'SAMPLE' => '1' })

      expect(output).to include("1 runs, 1 assertions, 0 failures, 0 errors, 0 skips")
    end

    specify "GROUP_SAMPLE=1" do
      output = run_minitest('sample', env: { 'GROUP_SAMPLE' => '1' })

      expect(output).to include("2 runs, 2 assertions, 0 failures, 0 errors, 0 skips")
    end

    specify "GROUP_SAMPLE=2" do
      output = run_minitest('sample', env: { 'GROUP_SAMPLE' => '2' })

      expect(output).to include("4 runs, 4 assertions, 0 failures, 0 errors, 0 skips")
    end
  end
end
