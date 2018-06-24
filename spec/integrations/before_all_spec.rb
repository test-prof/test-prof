# frozen_string_literal: true

require "spec_helper"

describe "BeforeAll" do
  context "RSpec" do
    specify "it works" do
      output = run_rspec('before_all')

      expect(output).to include("8 examples, 0 failures")
    end

    specify "it works with custom adapter" do
      output = run_rspec('before_all_custom_adapter')

      expect(output).to include("3 examples, 0 failures")
    end
  end

  context "Minitest" do
    specify "it works" do
      output = run_minitest('before_all')

      expect(output).to include("3 runs, 3 assertions, 0 failures, 0 errors, 0 skips")
    end
  end
end
