# frozen_string_literal: true

require "test_prof/rspec_dissect/printers/json"

describe TestProf::RSpecDissect::Printers::Json do
  let(:results) do
    {
      top_count: 5,
      total_time: 2.0,
      total_setup_time: 1.5,
      groups: [
        {
          description: "User",
          location: "./user_spec.rb:1",
          time: 2.0,
          count: 3,
          setup_time: 1.5,
          before_time: 1.0,
          before_let_time: 0.25,
          lazy_let_time: 0.5,
          top_lets: [{name: "user", duration: 0.5, size: 2}]
        }
      ]
    }
  end

  it "writes the envelope JSON with raw numeric values" do
    payload = nil
    allow(File).to receive(:write) { |_outpath, data| payload = data }

    described_class.dump(results)

    expect(JSON.parse(payload)).to eq(
      "profiler" => "rspec_dissect",
      "schema_version" => 1,
      "test_prof_version" => TestProf::VERSION,
      "data" => {
        "top_count" => 5,
        "total_time" => 2.0,
        "total_setup_time" => 1.5,
        "groups" => [
          {
            "description" => "User",
            "location" => "./user_spec.rb:1",
            "time" => 2.0,
            "count" => 3,
            "setup_time" => 1.5,
            "before_time" => 1.0,
            "before_let_time" => 0.25,
            "lazy_let_time" => 0.5,
            "top_lets" => [{"name" => "user", "duration" => 0.5, "size" => 2}]
          }
        ]
      }
    )
  end
end
