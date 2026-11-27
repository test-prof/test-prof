# frozen_string_literal: true

require "test_prof/factory_doctor"

describe TestProf::FactoryDoctor::Printers::Simple do
  context "with RSpec-like results (including group totals)" do
    let(:results) do
      {
        total_bad_examples: 2,
        total_wasted_time: 1.5,
        groups: [
          {
            description: "User",
            location: "./user_spec.rb:1",
            total_factories: 2,
            total_time: 1.5,
            examples: [
              {description: "works", location: "./user_spec.rb:2", factories: 1, time: 1.0},
              {description: "fails", location: "./user_spec.rb:3", factories: 1, time: 0.5}
            ]
          }
        ]
      }
    end

    let(:expected_report) do
      <<~REPORT
        FactoryDoctor report

        Total (potentially) bad examples: 2
        Total wasted time: 00:01.500

        User (./user_spec.rb:1) (2 records created, 00:01.500)
          works (./user_spec.rb:2) – 1 record created, 00:01.000
          fails (./user_spec.rb:3) – 1 record created, 00:00.500

      REPORT
    end

    it "renders the report" do
      described_class.dump(results)

      output = TestProf.config.output.string.delete_prefix("[TEST PROF INFO] ")

      expect(output).to include(expected_report)
    end
  end

  context "with Minitest-like results (without group totals)" do
    let(:results) do
      {
        total_bad_examples: 1,
        total_wasted_time: 1.0,
        groups: [
          {
            description: "UserTest",
            location: "./user_test.rb",
            examples: [
              {description: "works", location: "./user_test.rb:2", factories: 1, time: 1.0}
            ]
          }
        ]
      }
    end

    let(:expected_report) do
      <<~REPORT
        FactoryDoctor report

        Total (potentially) bad examples: 1
        Total wasted time: 00:01.000

        UserTest (./user_test.rb)
          works (./user_test.rb:2) – 1 record created, 00:01.000

      REPORT
    end

    it "renders the report" do
      described_class.dump(results)

      output = TestProf.config.output.string.delete_prefix("[TEST PROF INFO] ")

      expect(output).to include(expected_report)
    end
  end
end
