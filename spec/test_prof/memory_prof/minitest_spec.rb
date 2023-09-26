# frozen_string_literal: true

require "test_prof/memory_prof/minitest"

describe Minitest::TestProf::MemoryProfReporter do
  subject { described_class.new }

  let(:tracker) { subject.tracker }
  let(:printer) { subject.printer }

  before do
    allow(tracker).to receive(:start)
    allow(tracker).to receive(:finish)
    allow(tracker).to receive(:example_started)
    allow(tracker).to receive(:example_finished)
    allow(tracker).to receive(:group_started)
    allow(tracker).to receive(:group_finished)

    allow(printer).to receive(:print)

    allow(subject).to receive(:location_with_line_number).and_return("./test/models/reports.rb:57")
  end

  describe "#prerecord" do
    it "tracks the start of an example" do
      subject.prerecord("Report", "test_prepare")

      expect(tracker).to have_received(:example_started).with({
        name: "prepare",
        location: "./test/models/reports.rb:57"
      })
    end
  end

  describe "#record" do
    it "tracks the start of an example" do
      subject.prerecord("Report", "test_prepare")
      subject.record(nil)

      expect(tracker).to have_received(:example_started).with({
        name: "prepare",
        location: "./test/models/reports.rb:57"
      })
    end
  end

  describe "#start" do
    it "starts the tracking process" do
      subject.start

      expect(tracker).to have_received(:start)
    end
  end

  describe "#report" do
    it "finishes the tracking process" do
      subject.report

      expect(tracker).to have_received(:finish)
    end

    it "prints the results" do
      subject.report

      expect(printer).to have_received(:print)
    end
  end
end
