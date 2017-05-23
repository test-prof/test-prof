# frozen_string_literal: true

require "spec_helper"

describe TestProf::StackProf do
  # Use fresh config all for every example
  after { described_class.remove_instance_variable(:@config) }

  describe "#config" do
    subject { described_class.config }

    specify "defaults", :aggregate_failiures do
      expect(subject.mode).to eq :wall
      expect(subject.interval).to be_nil
      expect(subject.raw).to eq false
    end
  end

  describe "#profile" do
    let(:stack_prof) { double("stack_prof") }

    before do
      stub_const("StackProf", stack_prof)
    end

    specify "with default config" do
      expect(stack_prof).to receive(:start).with(
        mode: :wall,
        raw: false
      )

      described_class.profile
    end

    specify "with custom config" do
      described_class.config.raw = true
      described_class.config.mode = :cpu

      expect(stack_prof).to receive(:start).with(
        mode: :cpu,
        raw: true
      )

      described_class.profile
    end

    specify "when block is given" do
      expect(stack_prof).to receive(:run).with(
        out: "tmp/stack-prof-report-wall-stub.dump",
        mode: :wall,
        raw: false
      )

      described_class.profile("stub") { 0 == 1 }
    end
  end

  describe "#dump" do
    let(:stack_prof) { double("stack_prof") }

    before do
      stub_const("StackProf", stack_prof)
    end

    it "stops profiling and stores results" do
      expect(stack_prof).to receive(:results).with(
        "tmp/stack-prof-report-wall-stub.dump",
      )
      expect(stack_prof).to receive(:stop)
      described_class.dump("stub")
    end
  end
end
