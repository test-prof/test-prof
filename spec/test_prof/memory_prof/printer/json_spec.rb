# frozen_string_literal: true

require "test_prof/memory_prof"

describe TestProf::MemoryProf::JsonPrinter do
  let(:tracker) do
    instance_double(
      TestProf::MemoryProf::Tracker,
      top_count: 3,
      total_memory: 500,
      groups: [
        {name: "AnswersController", location: "./spec/controllers/answers_controller_spec.rb:3", memory: 200}
      ],
      examples: [
        {name: "returns nil", location: "./spec/models/reports_spec.rb:57", memory: 75}
      ]
    )
  end

  before do
    TestProf::MemoryProf.config.mode = "alloc"
  end

  it "writes the envelope JSON with raw numeric values" do
    payload = nil
    allow(File).to receive(:write) { |_outpath, data| payload = data }

    described_class.new(tracker).print

    expect(JSON.parse(payload)).to eq(
      "profiler" => "memory_prof",
      "schema_version" => 1,
      "test_prof_version" => TestProf::VERSION,
      "data" => {
        "mode" => "alloc",
        "top_count" => 3,
        "total" => 500,
        "groups" => [
          {"name" => "AnswersController", "location" => "./spec/controllers/answers_controller_spec.rb:3", "memory" => 200}
        ],
        "examples" => [
          {"name" => "returns nil", "location" => "./spec/models/reports_spec.rb:57", "memory" => 75}
        ]
      }
    )
  end
end
