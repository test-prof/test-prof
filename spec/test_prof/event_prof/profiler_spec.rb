# frozen_string_literal: true

require "spec_helper"

describe TestProf::EventProf::Profiler do
  let(:rank_by) { :time }
  let(:top_count) { 5 }
  let(:per_example) { false }

  let(:options) do
    {
      rank_by: rank_by,
      top_count: top_count,
      per_example: per_example
    }
  end

  subject { described_class.new(event: "test.event", instrumenter: InstrumenterStub, **options) }

  describe "#result" do
    before(:each) do
      subject.stub(:take_time).and_return(500)
    end

    let(:results) do
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
          { id: 'C', examples: 2, run_time: 500, time: 440, count: 2 },
          { id: 'B', examples: 2, run_time: 500, time: 420, count: 3 },
          { id: 'A', examples: 1, run_time: 500, time: 100, count: 1 }
        ]
      )
      expect(subject.total_time).to eq 960
      expect(subject.total_count).to eq 6
    end

    context "when rank by count" do
      let(:rank_by) { :count }

      it "returns top groups by event occurances" do
        expect(results).to eq(
          groups: [
            { id: 'B', examples: 2, run_time: 500, time: 420, count: 3 },
            { id: 'C', examples: 2, run_time: 500, time: 440, count: 2 },
            { id: 'A', examples: 1, run_time: 500, time: 100, count: 1 }
          ]
        )
      end
    end

    context "when top_count is specified" do
      let(:top_count) { 2 }

      it "returns top groups by event occurances" do
        expect(results).to eq(
          groups: [
            { id: 'C', examples: 2, run_time: 500, time: 440, count: 2 },
            { id: 'B', examples: 2, run_time: 500, time: 420, count: 3 }
          ]
        )
      end
    end

    context "when per_example is true" do
      let(:per_example) { true }

      it "returns top groups and examples" do
        expect(results).to eq(
          groups: [
            { id: 'C', examples: 2, run_time: 500, time: 440, count: 2 },
            { id: 'B', examples: 2, run_time: 500, time: 420, count: 3 },
            { id: 'A', examples: 1, run_time: 500, time: 100, count: 1 }
          ],
          examples: [
            { id: 'C1', run_time: 500, time: 440, count: 2 },
            { id: 'B1', run_time: 500, time: 380, count: 2 },
            { id: 'A1', run_time: 500, time: 100, count: 1 },
            { id: 'B2', run_time: 500, time: 40,  count: 1 }
          ]
        )
      end
    end
  end
end
