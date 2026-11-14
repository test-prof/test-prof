# frozen_string_literal: true

describe TestProf::Vernier do
  describe ".dump" do
    let(:result) { double("result") }
    let(:collector) { double("collector", stop: result) }
    let(:formatter) { double("formatter", output: output) }
    let(:output) { '{"threads":["café"]}' }
    let(:path) { TestProf.artifact_path("vernier-report-#{described_class.config.mode}-stub.json") }

    before do
      firefox = double("firefox")
      stub_const("Vernier::Output::Firefox", firefox)
      allow(firefox).to receive(:new).with(result).and_return(formatter)
      FileUtils.rm_f(path)
    end

    it "writes the report" do
      described_class.dump(collector, "stub")

      expect(File.binread(path)).to eq(output.b)
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
  end
end
