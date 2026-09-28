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

  describe "#print_group_result" do
    it "makes the setup time bold when color is on" do
      allow(TestProf.config).to receive(:color?).and_return(true)

      expect(collector.print_group_result(group)).to include("\e[1m00:01.500\e[22m")
    end

    it "writes no escape sequences when color is off" do
      allow(TestProf.config).to receive(:color?).and_return(false)

      result = collector.print_group_result(group)

      expect(result).to include("– 00:01.500 of 00:02.000")
      expect(result).not_to include("\e[")
    end
  end
end
