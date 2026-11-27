# frozen_string_literal: true

require "test_prof/rspec_dissect"

describe TestProf::RSpecDissect::Collector do
  subject(:collector) { described_class.new(top_count: 1) }

  let(:group) do
    {
      desc: "User",
      loc: "./user_spec.rb:1",
      total: 2.0,
      count: 3,
      total_setup: 1.5,
      total_lazy_let: 0.5,
      total_before_let: 0.25,
      top_lets: []
    }
  end

  describe "#<<" do
    it "collects group results" do
      collector << group

      expect(collector.results.to_a).to eq [group]
    end
  end
end
