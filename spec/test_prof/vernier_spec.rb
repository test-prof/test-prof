# frozen_string_literal: true

describe TestProf::Vernier do
  let(:result) { double("result") }
  let(:collector) { double("collector", start: nil, stop: result) }
  let(:formatter) { double("formatter") }
  let(:output) { '{"threads":["café"]}' }
  let(:path) { TestProf.artifact_path("vernier-report-#{described_class.config.mode}-stub.json") }
  let(:gzip_path) { "#{path}.gz" }

  around do |example|
    gzip = described_class.config.gzip
    described_class.config.gzip = false
    example.run
  ensure
    described_class.config.gzip = gzip
  end

  before do
    firefox = double("firefox")
    stub_const("Vernier::Output::Firefox", firefox)
    allow(firefox).to receive(:new).with(result).and_return(formatter)
    # Mirrors Vernier >= 1.0; calling with no args keeps Vernier < 1.0 working.
    allow(formatter).to receive(:output).with(no_args).and_return(output)
    allow(formatter).to receive(:output).with(gzip: true) { Zlib.gzip(output) }
    FileUtils.rm_f([path, gzip_path])
  end

  describe ".dump" do
    it "writes an uncompressed report by default" do
      described_class.dump(collector, "stub")

      expect(File.binread(path)).to eq(output.b)
      expect(File).not_to exist(gzip_path)
    end

    context "with a large report" do
      let(:output) { '{"threads":["' + ("é" * 1024) + '"]}' }

      # A single write(2) of 2 GiB or more fails with EINVAL on macOS,
      # so the report must be streamed rather than written in one call.
      it "streams the report via IO.copy_stream" do
        expect(IO).to receive(:copy_stream).and_call_original

        described_class.dump(collector, "stub")

        expect(File.binread(path)).to eq(output.b)
      end
    end

    context "when gzip is enabled" do
      before { described_class.config.gzip = true }

      it "streams a compressed report" do
        expect(IO).to receive(:copy_stream).and_call_original

        described_class.dump(collector, "stub")

        expect(Zlib.gunzip(File.binread(gzip_path))).to eq(output.b)
        expect(File).not_to exist(path)
      end

      context "with vernier < 1.0" do
        before do
          allow(TestProf::Utils).to receive(:verify_gem_version).with("vernier", at_least: "1.0.0").and_return(false)
        end

        it "warns and writes an uncompressed report" do
          described_class.dump(collector, "stub")

          expect(TestProf.config.output.string).to include("compression requires 'vernier' >= 1.0.0")
          expect(formatter).not_to have_received(:output).with(gzip: true)
          expect(File.binread(path)).to eq(output.b)
          expect(File).not_to exist(gzip_path)
        end
      end

      context "with a report suffix" do
        before { allow(TestProf.config).to receive(:report_suffix).and_return("ci") }

        let(:suffixed_path) do
          File.join(TestProf.config.output_dir, "vernier-report-#{described_class.config.mode}-stub-ci.json.gz")
        end

        after { FileUtils.rm_f(suffixed_path) }

        it "keeps the .json.gz extension" do
          described_class.dump(collector, "stub")

          expect(Zlib.gunzip(File.binread(suffixed_path))).to eq(output.b)
        end
      end
    end
  end

  describe ".profile" do
    before do
      stub_const("Vernier::Collector", double("collector class"))
      allow(Vernier::Collector).to receive(:new).and_return(collector)
    end

    it "dumps the report through .dump when given a block" do
      expect(described_class.profile("stub") { :done }).to eq(:done)

      expect(File.binread(path)).to eq(output.b)
    end

    it "dumps the report even if the block raises" do
      expect { described_class.profile("stub") { raise "boom" } }.to raise_error("boom")

      expect(File).to exist(path)
    end
  end
end
