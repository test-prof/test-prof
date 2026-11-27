# frozen_string_literal: true

require "test_prof/factory_doctor"

describe TestProf::FactoryDoctor::Printers::Json do
  let(:results) do
    {
      total_bad_examples: 2,
      total_wasted_time: 1.5,
      groups: [
        {
          description: "User",
          location: "./user_spec.rb:1",
          total_factories: 2,
          total_time: 1.5,
          examples: [
            {description: "works", location: "./user_spec.rb:2", factories: 1, time: 1.0},
            {description: "fails", location: "./user_spec.rb:3", factories: 1, time: 0.5}
          ]
        }
      ]
    }
  end

  it "writes the envelope JSON with raw numeric values" do
    payload = nil
    allow(File).to receive(:write) { |_outpath, data| payload = data }

    described_class.dump(results)

    expect(JSON.parse(payload)).to eq(
      "profiler" => "factory_doctor",
      "schema_version" => 1,
      "test_prof_version" => TestProf::VERSION,
      "data" => {
        "total_bad_examples" => 2,
        "total_wasted_time" => 1.5,
        "groups" => [
          {
            "description" => "User",
            "location" => "./user_spec.rb:1",
            "total_factories" => 2,
            "total_time" => 1.5,
            "examples" => [
              {"description" => "works", "location" => "./user_spec.rb:2", "factories" => 1, "time" => 1.0},
              {"description" => "fails", "location" => "./user_spec.rb:3", "factories" => 1, "time" => 0.5}
            ]
          }
        ]
      }
    )
  end
end
