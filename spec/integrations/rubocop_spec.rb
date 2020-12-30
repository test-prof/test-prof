# frozen_string_literal: true

describe "RuboCop cops" do
  context "AggregateExamples" do
    specify do
      output = run_rubocop("aggregate_failures", cop: "RSpec/AggregateExamples")

      expect(output).to include("1 offense detected")
    end
  end
end
