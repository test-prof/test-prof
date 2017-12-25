# frozen_string_literal: true

require "spec_helper"

describe TestProf do
  describe "#artifact_path" do
    before do
      described_class.config.output_dir = "tmp/test"
    end

    context "ensures creation of output_dir" do
      subject { described_class.artifact_path("c.html") }

      before { FileUtils.rmdir(described_class.config.output_dir) if File.directory?(described_class.config.output_dir) }

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

  describe "#require" do
    context "when second argument omitted" do
      context "when Kernel.require fails" do
        it "returns false without logging" do
          allow(Kernel).to receive(:require).with("non-existent").and_raise(LoadError)
          allow(described_class).to receive(:require).with("non-existent")
                                                     .and_call_original
          expect(described_class.require("non-existent")).to eq false
          expect(described_class).not_to receive(:log).with(:error, nil)
          described_class.require("non-existent", nil)
        end
      end

      context "when Kernel.require succeeds" do
        context "when block given" do
          it "yields block" do
            allow(Kernel).to receive(:require).with("something").and_return(true)
            allow(described_class).to receive(:require).with("something") { 2 + 2 }
                                                       .and_call_original
            expect(described_class.require("something") { 2 + 2 }).to eq 4
          end
        end

        context "when no block given" do
          it "returns true" do
            allow(Kernel).to receive(:require).with("something").and_return(true)
            allow(described_class).to receive(:require).with("something").and_call_original
            expect(described_class.require("something")).to eq true
          end
        end
      end
    end

    context "when two arguments supplied" do
      context "when Kernel.require fails" do
        it "returns false with log output" do
          allow(Kernel).to receive(:require).with("non-existent").and_raise(LoadError)
          allow(described_class).to receive(:require).with("non-existent", "message")
                                                     .and_call_original
          expect(described_class.require("non-existent", "message")).to eq false
          expect(described_class).to receive(:log).with(:error, "message")
          described_class.require("non-existent", "message")
        end
      end

      context "when Kernel.require succeeds" do
        context "when block given" do
          it "yields block" do
            allow(Kernel).to receive(:require).with("something").and_return(true)
            allow(described_class).to receive(:require).with("something", "message") { 2 + 2 }
                                                       .and_call_original
            expect(described_class.require("something", "message") { 2 + 2 }).to eq 4
          end
        end

        context "when no block given" do
          it "returns true" do
            allow(Kernel).to receive(:require).with("something").and_return(true)
            allow(described_class).to receive(:require).with("something").and_call_original
            expect(described_class.require("something")).to eq true
          end
        end
      end
    end
  end
end
