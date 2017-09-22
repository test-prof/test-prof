# frozen_string_literal: true

require "spec_helper"

describe TestProf do
  describe "#artifact_path" do
    before do
      described_class.config.output_dir = "tmp/test"
    end

    context "ensures creation of output_dir" do
      subject { described_class.artifact_path("c.html") }

      before { FileUtils.rmdir described_class.config.output_dir }

      it { expect { subject }.to(change { File.exist?(described_class.config.output_dir) }) }
    end

    context "without timestamps" do
      before { described_class.config.timestamps = false }

      it { expect(described_class.artifact_path("c.html")).to eq 'tmp/test/c.html' }
    end

    context "with timestamps" do
      before do
        described_class.config.timestamps = true
        expect(described_class).to receive(:now).and_return(double("now", to_i: 123_454_321))
      end

      it { expect(described_class.artifact_path("c.html")).to eq 'tmp/test/c-123454321.html' }
      it { expect(described_class.artifact_path("c")).to eq 'tmp/test/c-123454321' }
    end
  end
end
