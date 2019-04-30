# frozen_string_literal: true

require "spec_helper"

describe "BeforeAll" do
  context "RSpec" do
    specify "it works" do
      output = run_rspec("before_all")

      expect(output).to include("11 examples, 0 failures")
    end

    specify "it sets up each before_all block" do
      output = run_rspec("setup_before_all")

      expect(output).to include("3 examples, 0 failures")
    end

    specify "it works with custom adapter" do
      output = run_rspec("before_all_custom_adapter")

      expect(output).to include("3 examples, 0 failures")
    end

    specify "it works with isolator" do
      output = run_rspec("before_all_isolator", success: false)

      expect(output).to include("2 examples, 1 failure")
      expect(output).not_to include("SampleJob")
      expect(output).to include("FailingJob")
    end
  end

  context "Minitest" do
    specify "it works" do
      output = run_minitest("before_all")

      expect(output).to include("3 runs, 3 assertions, 0 failures, 0 errors, 0 skips")
    end
  end
end
