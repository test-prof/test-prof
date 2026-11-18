# frozen_string_literal: true

require "test_prof/printers/json"

describe TestProf::Printers::Json do
  let(:printer) do
    Class.new do
      include TestProf::Printers::Json

      def self.dump(data)
        new.dump(data)
      end

      def dump(data)
        dump_json("test_profiler", data, filename: "test-profiler.json")
      end
    end
  end

  before do
    allow(File).to receive(:write)
    allow(TestProf).to receive(:artifact_path).and_call_original
  end

  it "writes the envelope JSON to a deterministic artifact path" do
    printer.dump(total: 1.5)

    expect(TestProf).to have_received(:artifact_path).with("test-profiler.json", timestamps: false)

    outpath = TestProf.artifact_path("test-profiler.json", timestamps: false)
    expect(File).to have_received(:write).with(outpath, String).once
  end

  it "wraps the payload into the uniform envelope" do
    payload = nil
    allow(File).to receive(:write) { |_outpath, data| payload = data }

    printer.dump(total: 1.5, count: 2)

    expect(JSON.parse(payload)).to eq(
      "profiler" => "test_profiler",
      "schema_version" => 1,
      "test_prof_version" => TestProf::VERSION,
      "data" => {"total" => 1.5, "count" => 2}
    )
  end

  it "logs the standardized report line" do
    printer.dump(total: 1.5)

    expect(TestProf.config.output.string).to match(%r{\[TEST PROF INFO\] Report written: profiler=test_profiler path=.*test-profiler\.json})
  end

  describe "manifest registration" do
    before { TestProf::Reports.reset! }

    after { TestProf::Reports.reset! }

    it "registers the report when TEST_PROF_FORMAT=json" do
      allow(TestProf).to receive(:json_format?).and_return(true)

      printer.dump(total: 1.5)

      manifest = nil
      allow(File).to receive(:write) { |_outpath, data| manifest = data }

      TestProf::Reports.write

      expect(JSON.parse(manifest)).to include("reports" => [include("profiler" => "test_profiler")])
    end

    it "doesn't register the report when TEST_PROF_FORMAT is not set" do
      allow(TestProf).to receive(:json_format?).and_return(false)

      printer.dump(total: 1.5)

      outpath = TestProf.artifact_path("index.json", timestamps: false)
      expect(File).not_to have_received(:write).with(outpath, String)
    end

    it "writes the manifest after the suite" do
      allow(TestProf).to receive(:json_format?).and_return(true)

      printer.dump(total: 1.5)

      manifest = nil
      allow(File).to receive(:write) { |_outpath, data| manifest = data }

      TestProf::Reports.write

      reports = JSON.parse(manifest).fetch("reports")
      expect(reports).to contain_exactly(
        include("profiler" => "test_profiler", "path" => end_with("test-profiler.json"))
      )
    end
  end
end
