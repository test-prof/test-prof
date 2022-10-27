# frozen_string_literal: true

describe TestProf::StackProf do
  # Use fresh config all for every example
  after { described_class.remove_instance_variable(:@config) }

  describe ".config" do
    subject { described_class.config }

    specify "defaults", :aggregate_failures do
      expect(subject.mode).to eq :wall
      expect(subject.interval).to be_nil
      expect(subject.raw).to eq true
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
        raw: true
      )

      described_class.profile
    end

    specify "with custom config" do
      described_class.config.raw = false
      described_class.config.mode = :cpu

      expect(stack_prof).to receive(:start).with(
        mode: :cpu,
        raw: false
      )

      described_class.profile
    end

    specify "with ignore_gc option" do
      described_class.config.ignore_gc = true

      expect(stack_prof).to receive(:start).with(
        mode: :wall,
        raw: true,
        ignore_gc: true
      )

      described_class.profile
    end

    specify "when block is given" do
      expect(stack_prof).to receive(:run).with(
        out: File.join(TestProf.config.output_dir, "stack-prof-report-wall-raw-stub.dump").to_s,
        mode: :wall,
        raw: true
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
        File.join(TestProf.config.output_dir, "stack-prof-report-wall-raw-stub.dump").to_s
      )
      expect(stack_prof).to receive(:stop)
      described_class.dump("stub")
    end
  end
end
