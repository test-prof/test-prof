# frozen_string_literal: true

require "spec_helper"

describe TestProf do
  describe "#with_timestamps" do
    context "when enabled" do
      before { described_class.config.timestamps = false }

      it { expect(described_class.with_timestamps("a/b/c.html")).to eq 'a/b/c.html' }
    end

    context "when enabled" do
      before do
        described_class.config.timestamps = true
        expect(Time).to receive(:now).and_return(double("now", to_i: 123_454_321))
      end

      it { expect(described_class.with_timestamps("a/b/c.html")).to eq 'a/b/c-123454321.html' }
      it { expect(described_class.with_timestamps("a/b/c")).to eq 'a/b/c-123454321' }
    end
  end
end
