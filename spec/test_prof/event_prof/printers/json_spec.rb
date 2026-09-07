# frozen_string_literal: true

describe TestProf::EventProf::Printers::Json do
  let(:group_id) do
    Struct.new(:top_level_description, :metadata).new("Something", location: "./spec/models/user_spec.rb:10")
  end

  let(:example_id) do
    Struct.new(:description, :metadata).new("works", location: "./spec/models/user_spec.rb:12")
  end

  let(:minitest_group_id) do
    {name: "SomethingTest", location: "./test/models/user_test.rb"}
  end

  let(:minitest_example_id) do
    {name: "works", location: "./test/models/user_test.rb:5"}
  end

  let(:results) do
    {
      groups: [
        {id: group_id, time: 0.5, run_time: 2.5, count: 4, examples: 2}
      ],
      examples: [
        {id: example_id, time: 0.25, run_time: 1.0, count: 2}
      ]
    }
  end

  let(:profiler) do
    Struct.new(:event, :total_time, :total_count, :absolute_run_time, :rank_by, :top_count, :results)
      .new("test.event", 0.5, 4, 2.5, :time, 5, results)
  end

  describe "#dump" do
    before do
      allow(File).to receive(:write)
      allow(TestProf).to receive(:artifact_path).and_return("event-prof.json")
    end

    it "writes json" do
      described_class.dump([profiler])
      outpath = TestProf.artifact_path("event-prof.json")
      expect(File).to have_received(:write).with(outpath, String).once
    end

    it "converts profiler results with RSpec ids" do
      data = JSON.parse(dump_payload).first

      expect(data).to include(
        "event" => "test.event",
        "total_time" => "00:00.500",
        "total_count" => 4,
        "absolute_run_time" => "00:02.500",
        "time_percentage" => 20.0,
        "rank_by" => "time",
        "top_count" => 5
      )

      expect(data["groups"]).to contain_exactly(
        include(
          "description" => "Something",
          "location" => "./spec/models/user_spec.rb:10",
          "time" => "00:00.500",
          "run_time" => "00:02.500",
          "time_percentage" => 20.0,
          "count" => 4,
          "examples" => 2
        )
      )

      expect(data["examples"]).to contain_exactly(
        include(
          "description" => "works",
          "location" => "./spec/models/user_spec.rb:12",
          "time" => "00:00.250",
          "run_time" => "00:01.000",
          "time_percentage" => 25.0,
          "count" => 2
        )
      )
    end

    it "converts profiler results with Minitest ids" do
      results[:groups] = [{id: minitest_group_id, time: 0.5, run_time: 2.5, count: 4, examples: 2}]
      results[:examples] = [{id: minitest_example_id, time: 0.25, run_time: 1.0, count: 2}]

      data = JSON.parse(dump_payload).first

      expect(data["groups"]).to contain_exactly(
        include(
          "description" => "SomethingTest",
          "location" => "./test/models/user_test.rb"
        )
      )

      expect(data["examples"]).to contain_exactly(
        include(
          "description" => "works",
          "location" => "./test/models/user_test.rb:5"
        )
      )
    end

    it "omits examples when profiling is not per-example" do
      results.delete(:examples)

      data = JSON.parse(dump_payload).first

      expect(data).not_to have_key("examples")
    end
  end

  private

  def dump_payload
    payload = nil
    allow(File).to receive(:write) { |_outpath, data| payload = data }
    described_class.dump([profiler])
    payload
  end
end
