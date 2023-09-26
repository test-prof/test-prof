# frozen_string_literal: true

describe TestProf::MemoryProf::Printer::NumberToHuman do
  subject { described_class }

  describe "#convert" do
    let(:convert) { subject.convert(number) }

    context "when number is 0" do
      let(:number) { 0 }

      it "returns 0B" do
        expect(convert).to eq("0B")
      end
    end

    context "when number < 1KB" do
      let(:number) { 700 }

      it "returns the value in bytes" do
        expect(convert).to eq("700B")
      end
    end

    context "when number > 1024 ZB" do
      let(:number) { 7 * 2**80 }

      it "returns the value in ZB" do
        expect(convert).to eq("7168ZB")
      end
    end

    context "when number can be converted to an integer" do
      let(:number) { 7 * 2**20 }

      it "returns the value as an integer" do
        expect(convert).to eq("7MB")
      end
    end

    context "when number can not be converted to an integer" do
      let(:number) { 7 * 2**20 + 550 * 2**10 }

      it "rounds the value to two digits" do
        expect(convert).to eq("7.54MB")
      end
    end
  end
end
