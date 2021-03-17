# frozen_string_literal: true

describe "TagProf" do
  specify "it works", :aggregate_failures do
    output = run_rspec("tag_prof", env: {"TAG_PROF" => "type"})

    expect(output).to include("TagProf report for type")
    expect(output).to match(/type\s+time\s+total\s+%total\s+%time\s+avg\n\n/)
    expect(output).to match(/fail\s+\d{2}:\d{2}\.\d{3}\s+1\s+/)
    expect(output).to match(/pass\s+\d{2}:\d{2}\.\d{3}\s+2\s+/)
    expect(output).to match(/__unknown__\s+\d{2}:\d{2}\.\d{3}\s+1\s+/)
  end

  specify "html report" do
    output = run_rspec("tag_prof", env: {"TAG_PROF" => "type", "TAG_PROF_FORMAT" => "html"})

    expect(output).to include("TagProf report generated:")

    expect(File.exist?("tmp/test_prof/tag-prof.html")).to eq true
  end

  context "with events" do
    specify "it works", :aggregate_failures do
      output = run_rspec(
        "tag_prof",
        env: {"TAG_PROF" => "type", "TAG_PROF_EVENT" => "test.event,test.event2"}
      )

      expect(output).to include("TagProf report for type")
      expect(output).to match(/type\s+time\s+test\.event\s+test.event2\s+total\s+%total\s+%time\s+avg\n\n/)
      expect(output).to match(/fail\s+\d{2}:\d{2}\.\d{3}\s+00:23.000\s+00:00.000\s+1\s+/)
      expect(output).to match(/pass\s+\d{2}:\d{2}\.\d{3}\s+00:12.420\s+00:14.041\s+2\s+/)
      expect(output).to match(/__unknown__\s+\d{2}:\d{2}\.\d{3}\s+00:00.000\s+00:00.000\s+1\s+/)
    end
  end
end
