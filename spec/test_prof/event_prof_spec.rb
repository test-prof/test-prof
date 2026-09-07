# frozen_string_literal: true

describe TestProf::EventProf do
  # Use fresh config all for every example
  after { described_class.remove_instance_variable(:@config) }

  before { stub_const("ActiveSupport::Notifications", double(subscribe: nil)) }

  subject { described_class.build }

  describe ".build" do
    before { described_class.config.event = "test.event" }

    it "subscribes to event" do
      expect(TestProf::EventProf::Instrumentations::ActiveSupport)
        .to receive(:subscribe).with("test.event")
      subject
    end

    it "sets options" do
      expect(subject.events).to eq ["test.event"]
      expect(subject.profilers.first.rank_by).to eq :time
      expect(subject.profilers.first.top_count).to eq 5
    end
  end

  describe "Config#printer" do
    it "returns Simple printer by default" do
      expect(described_class.config.printer).to eq TestProf::EventProf::Printers::Simple
    end

    it "returns Json printer for string format" do
      described_class.config.format = "json"
      expect(described_class.config.printer).to eq TestProf::EventProf::Printers::Json
    end

    it "returns Json printer for symbol format" do
      described_class.config.format = :json
      expect(described_class.config.printer).to eq TestProf::EventProf::Printers::Json
    end
  end
end
