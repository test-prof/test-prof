# frozen_string_literal: true

require "test_prof/tag_prof"

describe TestProf::TagProf::Printers::Json do
  let(:result) do
    TestProf::TagProf::Result.new(:type, ["test.event"]).tap do |result|
      result.track(:pass, time: 1.5, events: {"test.event" => 0.25})
      result.track(:fail, time: 0.5, events: {"test.event" => 0.0})
    end
  end

  it "writes the envelope JSON with raw numeric values" do
    payload = nil
    allow(File).to receive(:write) { |_outpath, data| payload = data }

    described_class.dump(result)

    envelope = JSON.parse(payload)

    expect(envelope).to include(
      "profiler" => "tag_prof",
      "schema_version" => 1,
      "test_prof_version" => TestProf::VERSION
    )

    expect(envelope.dig("data", "tag")).to eq "type"
    expect(envelope.dig("data", "events")).to eq ["test.event"]

    expect(envelope.dig("data", "data")).to contain_exactly(
      {"value" => "pass", "count" => 1, "time" => 1.5, "test.event" => 0.25},
      {"value" => "fail", "count" => 1, "time" => 0.5, "test.event" => 0.0}
    )
  end
end
