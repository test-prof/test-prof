# frozen_string_literal: true

require "test_prof/rspec_dissect/printers/simple"

describe TestProf::RSpecDissect::Printers::Simple do
  let(:results) do
    {
      top_count: 5,
      total_time: 2.0,
      total_setup_time: 1.5,
      groups: [
        {
          description: "User",
          location: "./user_spec.rb:1",
          time: 2.0,
          count: 3,
          setup_time: 1.5,
          before_time: 1.0,
          before_let_time: 0.25,
          lazy_let_time: 0.5,
          top_lets: [{name: "user", duration: 0.5, size: 2}]
        }
      ]
    }
  end

  let(:expected_report) do
    <<~REPORT
      RSpecDissect report

      Total time: 00:02.000
      Total setup time: 00:01.500


      Top 5 slowest suites by setup time:

      User (./user_spec.rb:1) – 00:01.500 of 00:02.000 / 3 (before: 00:01.000, before let: 00:00.250, lazy let: 00:00.500)
       ↳ user – 00:00.500 (2)

    REPORT
  end

  it "renders the report" do
    described_class.dump(results)

    output = TestProf.config.output.string.delete_prefix("[TEST PROF INFO] ")

    expect(output).to include(expected_report)
  end

  describe "#print_group_result" do
    let(:group) { results[:groups].first }

    it "makes the setup time bold when color is on" do
      allow(TestProf.config).to receive(:color?).and_return(true)

      expect(described_class.send(:print_group_result, group)).to include("\e[1m00:01.500\e[22m")
    end

    it "writes no escape sequences when color is off" do
      allow(TestProf.config).to receive(:color?).and_return(false)

      result = described_class.send(:print_group_result, group)

      expect(result).to include("– 00:01.500 of 00:02.000")
      expect(result).not_to include("\e[")
    end
  end
end
