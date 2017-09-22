# frozen_string_literal: true

require "spec_helper"

describe TestProf::EventProf do
  # Use fresh config all for every example
  after { described_class.remove_instance_variable(:@config) }

  before { stub_const("ActiveSupport::Notifications", double(subscribe: nil)) }

  subject { described_class.build }

  describe ".config" do
    specify "defaults", :aggregate_failures do
      expect(subject.top_count).to eq 5
      expect(subject.rank_by).to eq :time
    end
  end

  describe ".build" do
    before { described_class.config.event = 'test.event' }

    it "subscribes to event" do
      expect(TestProf::EventProf::Instrumentations::ActiveSupport)
        .to receive(:subscribe).with('test.event')
      subject
    end

    it "sets options" do
      expect(subject.event).to eq 'test.event'
      expect(subject.rank_by).to eq :time
      expect(subject.top_count).to eq 5
    end
  end

  describe "#result" do
    let(:results) do
      described_class.config.event = 'test.event'
      described_class.config.instrumenter = InstrumenterStub

      subject

      subject.group_started 'A'

      subject.example_started 'A1'
      InstrumenterStub.notify 'test.event', 100
      subject.example_finished 'A1'

      subject.group_finished 'A'

      subject.group_started 'B'

      subject.example_started 'B1'
      InstrumenterStub.notify 'test.event', 140
      InstrumenterStub.notify 'test.event', 240
      subject.example_finished 'B1'

      subject.example_started 'B2'
      InstrumenterStub.notify 'test.event', 40
      subject.example_finished 'B2'

      subject.group_finished 'B'

      subject.group_started 'C'

      subject.example_started 'C1'
      InstrumenterStub.notify 'test.event', 400
      InstrumenterStub.notify 'test.event', 40
      subject.example_finished 'C1'

      subject.example_started 'C2'
      subject.example_finished 'C2'

      subject.group_finished 'C'

      subject.results
    end

    it "returns top slow groups and totals" do
      expect(results).to eq(
        groups: [
          { id: 'C', examples: 2, time: 440, count: 2 },
          { id: 'B', examples: 2, time: 420, count: 3 },
          { id: 'A', examples: 1, time: 100, count: 1 }
        ]
      )
      expect(subject.total_time).to eq 960
      expect(subject.total_count).to eq 6
    end

    context "when rank by count" do
      before { described_class.config.rank_by = :count }

      it "returns top groups by event occurances" do
        expect(results).to eq(
          groups: [
            { id: 'B', examples: 2, time: 420, count: 3 },
            { id: 'C', examples: 2, time: 440, count: 2 },
            { id: 'A', examples: 1, time: 100, count: 1 }
          ]
        )
      end
    end

    context "when top_count is specified" do
      before { described_class.config.top_count = 2 }

      it "returns top groups by event occurances" do
        expect(results).to eq(
          groups: [
            { id: 'C', examples: 2, time: 440, count: 2 },
            { id: 'B', examples: 2, time: 420, count: 3 }
          ]
        )
      end
    end

    context "when per_example is true" do
      before { described_class.config.per_example = true }

      it "returns top groups and examples" do
        expect(results).to eq(
          groups: [
            { id: 'C', examples: 2, time: 440, count: 2 },
            { id: 'B', examples: 2, time: 420, count: 3 },
            { id: 'A', examples: 1, time: 100, count: 1 }
          ],
          examples: [
            { id: 'C1', time: 440, count: 2 },
            { id: 'B1', time: 380, count: 2 },
            { id: 'A1', time: 100, count: 1 },
            { id: 'B2', time: 40,  count: 1 }
          ]
        )
      end
    end
  end
end
