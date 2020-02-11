# frozen_string_literal: true

describe "RuboCop cops" do
  context "AggregateExamples" do
    specify do
      output = run_rubocop("aggregate_failures", cop: "RSpec/AggregateExamples")

      expect(output).to include("1 offense detected")
    end
  end

  context "AggregateFailures" do
    specify do
      raise "Remove deprecated AggregateFailures" if TestProf::VERSION >= "1.0"

      output = run_rubocop("aggregate_failures", cop: "RSpec/AggregateFailures")

      expect(output).to include("cop has been renamed")
      expect(output).to include("1 offense detected")
    end
  end
end
