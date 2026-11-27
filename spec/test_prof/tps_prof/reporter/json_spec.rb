# frozen_string_literal: true

require "test_prof/tps_prof"

describe TestProf::TPSProf::Reporter::Json do
  let(:group_id) do
    Struct.new(:top_level_description, :metadata).new("Something", location: "./spec/models/user_spec.rb:10")
  end

  let(:profiler) do
    Struct.new(:mode, :top_count, :total_count, :total_time, :groups)
      .new(:profile, 10, 4, 2.0, [group])
  end

  let(:group) do
    {
      id: group_id,
      total_time: 1.5,
      shared_setup_time: 0.5,
      count: 3,
      tps: 2.0,
      penalty: 0.25
    }
  end

  it "writes the envelope JSON with raw numeric values" do
    payload = nil
    allow(File).to receive(:write) { |_outpath, data| payload = data }

    described_class.new.print(profiler)

    expect(JSON.parse(payload)).to eq(
      "profiler" => "tps_prof",
      "schema_version" => 1,
      "test_prof_version" => TestProf::VERSION,
      "data" => {
        "mode" => "profile",
        "top_count" => 10,
        "total_count" => 4,
        "total_time" => 2.0,
        "total_tps" => 2.0,
        "groups" => [
          {
            "description" => "Something",
            "location" => "./spec/models/user_spec.rb:10",
            "total_time" => 1.5,
            "shared_setup_time" => 0.5,
            "count" => 3,
            "tps" => 2.0,
            "penalty" => 0.25
          }
        ]
      }
    )
  end
end
