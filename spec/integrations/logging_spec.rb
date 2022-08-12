# frozen_string_literal: true

describe "Logging" do
  context "RSpec integration" do
    specify "global all", :aggregate_failures do
      output = run_rspec("logging", env: {"LOG" => "all"}, options: "--tag test:global")

      expect(output).to include("examples, 0 failures")

      expect(output).to include("INSERT INTO")
      expect(output).to include("USER: a")
      expect(output).to include("USER: b")
    end

    specify "global active record", :aggregate_failures do
      output = run_rspec("logging", env: {"LOG" => "ar"}, options: "--tag test:global")

      expect(output).to include("examples, 0 failures")

      expect(output).to include("INSERT INTO")
      expect(output).not_to include("USER: a")
      expect(output).not_to include("USER: b")
    end

    specify "tegs", :aggregate_failures do
      output = run_rspec("logging", env: {"LOG" => "ar"}, options: "--tag test:tags")

      expect(output).to include("examples, 0 failures")

      expect(output).to include("INSERT INTO")
      expect(output).not_to include("USER: invisible")
      expect(output).to include("USER: visible")
    end
  end
end
