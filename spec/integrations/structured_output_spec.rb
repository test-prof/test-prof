# frozen_string_literal: true

describe "Structured output" do
  context "RSpec" do
    let(:env) do
      {
        "TEST_PROF_FORMAT" => "json",
        "FPROF" => "1",
        "RD_PROF" => "1",
        "TAG_PROF" => "type",
        "EVENT_PROF" => "test.event",
        "TPS_PROF" => "1"
      }
    end

    let(:reports) do
      {
        "rspec_dissect" => "tmp/test_prof/rspec-dissect.json",
        "tag_prof" => "tmp/test_prof/tag-prof.json",
        "event_prof" => "tmp/test_prof/event-prof.json",
        "tps_prof" => "tmp/test_prof/tps-prof.json",
        "factory_prof" => "tmp/test_prof/test-prof.result.json"
      }
    end

    after { FileUtils.rm_rf("tmp/test_prof") }

    specify "all profilers emit a well-formed envelope plus a manifest", :aggregate_failures do
      output = run_rspec("structured_output", env: env)

      reports.each do |profiler, artifact|
        expect(output).to include("Report written: profiler=#{profiler}")

        envelope = JSON.parse(File.read(artifact))

        expect(envelope).to include(
          "profiler" => profiler,
          "schema_version" => 1,
          "test_prof_version" => TestProf::VERSION
        )
        expect(envelope).to have_key("data")
      end

      manifest = JSON.parse(File.read("tmp/test_prof/index.json"))

      expect(manifest).to include(
        "schema_version" => 1,
        "test_prof_version" => TestProf::VERSION
      )

      expect(manifest.fetch("reports").map { |report| report["profiler"] })
        .to match_array(reports.keys)
    end
  end

  context "Minitest" do
    let(:env) { {"TEST_PROF_FORMAT" => "json", "TAG_PROF" => "type"} }

    after { FileUtils.rm_rf("tmp/test_prof") }

    specify "TagProf emits a well-formed envelope plus a manifest", :aggregate_failures do
      output = run_minitest("structured_output", env: env)

      expect(output).to include("Report written: profiler=tag_prof")

      envelope = JSON.parse(File.read("tmp/test_prof/tag-prof.json"))

      expect(envelope).to include(
        "profiler" => "tag_prof",
        "schema_version" => 1,
        "test_prof_version" => TestProf::VERSION
      )

      manifest = JSON.parse(File.read("tmp/test_prof/index.json"))

      expect(manifest.fetch("reports")).to contain_exactly(
        include("profiler" => "tag_prof", "path" => end_with("tag-prof.json"))
      )
    end
  end
end
