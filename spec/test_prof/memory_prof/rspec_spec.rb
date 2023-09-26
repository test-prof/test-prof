# frozen_string_literal: true

require "test_prof/memory_prof/rspec"

describe TestProf::MemoryProf::RSpecListener do
  subject { described_class.new }

  let(:tracker) { subject.tracker }
  let(:printer) { subject.printer }

  let(:example) do
    instance_double(
      RSpec::Core::Example,
      description: "returns nil",
      metadata: {location: "./spec/models/reports_spec.rb:57"}
    )
  end

  let(:group) do
    double(
      RSpec::Core::ExampleGroup,
      description: "#publish",
      metadata: {location: "./spec/nodels/question_spec.rb:179"}
    )
  end

  before do
    tracker = instance_double(
      TestProf::MemoryProf::Tracker,
      start: nil,
      finish: nil,
      example_started: nil,
      example_finished: nil,
      group_started: nil,
      group_finished: nil
    )

    allow(TestProf::MemoryProf).to receive(:tracker).and_return(tracker)
    allow(printer).to receive(:print)
  end

  xdescribe "#initialize" do
    it "starts the tracking process" do
      subject

      expect(tracker).to have_received(:start)
    end
  end

  describe "#example_started" do
    let(:notification) do
      RSpec::Core::Notifications::ExampleNotification.send(:new, example)
    end

    it "tracks the start of an example" do
      subject.example_started(notification)

      expect(tracker).to have_received(:example_started).with({
        name: "returns nil",
        location: "./spec/models/reports_spec.rb:57"
      })
    end
  end

  describe "#example_finished" do
    let(:notification) do
      RSpec::Core::Notifications::ExampleNotification.send(:new, example)
    end

    it "tracks the end of an example" do
      subject.example_finished(notification)

      expect(tracker).to have_received(:example_finished).with({
        name: "returns nil",
        location: "./spec/models/reports_spec.rb:57"
      })
    end
  end

  describe "#example_group_started" do
    let(:notification) do
      RSpec::Core::Notifications::GroupNotification.send(:new, group)
    end

    it "tracks the end of an example" do
      subject.example_group_started(notification)

      expect(tracker).to have_received(:group_started).with({
        name: "#publish",
        location: "./spec/nodels/question_spec.rb:179"
      })
    end
  end

  describe "#example_group_finished" do
    let(:notification) do
      RSpec::Core::Notifications::GroupNotification.send(:new, group)
    end

    it "tracks the end of an example" do
      subject.example_group_finished(notification)

      expect(tracker).to have_received(:group_finished).with({
        name: "#publish",
        location: "./spec/nodels/question_spec.rb:179"
      })
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
