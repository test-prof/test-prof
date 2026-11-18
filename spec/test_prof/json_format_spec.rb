# frozen_string_literal: true

require "test_prof/rspec_dissect"
require "test_prof/factory_doctor"
require "test_prof/tag_prof"
require "test_prof/memory_prof"

describe "TEST_PROF_FORMAT=json" do
  # Save and restore ENV around each example
  around do |example|
    env = ENV.to_h
    example.run
  ensure
    ENV.replace(env)
  end

  after do
    [TestProf::EventProf, TestProf::FactoryProf, TestProf::TPSProf, TestProf::MemoryProf, TestProf::RSpecDissect].each do |mod|
      mod.remove_instance_variable(:@config) if mod.instance_variable_defined?(:@config)
    end
  end

  context "by default" do
    it "keeps text printers for all profilers" do
      expect(TestProf::FactoryProf.config.printer).to eq TestProf::FactoryProf::Printers::Simple
      expect(TestProf::EventProf.config.printer).to eq TestProf::EventProf::Printers::Simple
      expect(TestProf::TagProf.printer).to eq TestProf::TagProf::Printers::Simple
      expect(TestProf::TPSProf::Configuration.new.reporter).to be_a TestProf::TPSProf::Reporter::Text
      expect(TestProf::RSpecDissect::Listener.new.send(:printer)).to eq TestProf::RSpecDissect::Printers::Simple
      expect(TestProf::FactoryDoctor::RSpecListener.new.send(:printer)).to eq TestProf::FactoryDoctor::Printers::Simple
      expect(TestProf::MemoryProf.printer(double("tracker"))).to be_a TestProf::MemoryProf::RssPrinter
    end
  end

  context "when set to json" do
    before { ENV["TEST_PROF_FORMAT"] = "json" }

    it "switches all profilers to JSON printers" do
      expect(TestProf::FactoryProf.config.printer).to eq TestProf::FactoryProf::Printers::Json
      expect(TestProf::EventProf.config.printer).to eq TestProf::EventProf::Printers::Json
      expect(TestProf::TagProf.printer).to eq TestProf::TagProf::Printers::Json
      expect(TestProf::TPSProf::Configuration.new.reporter).to be_a TestProf::TPSProf::Reporter::Json
      expect(TestProf::RSpecDissect::Listener.new.send(:printer)).to eq TestProf::RSpecDissect::Printers::Json
      expect(TestProf::FactoryDoctor::RSpecListener.new.send(:printer)).to eq TestProf::FactoryDoctor::Printers::Json
      expect(TestProf::MemoryProf.printer(double("tracker"))).to be_a TestProf::MemoryProf::JsonPrinter
    end

    context "and per-profiler variables act as overrides" do
      it "respects FPROF=flamegraph" do
        ENV["FPROF"] = "flamegraph"

        expect(TestProf::FactoryProf.config.printer).to eq TestProf::FactoryProf::Printers::Flamegraph
      end

      it "respects FPROF=1" do
        ENV["FPROF"] = "1"

        expect(TestProf::FactoryProf.config.printer).to eq TestProf::FactoryProf::Printers::Json
      end

      it "respects EVENT_PROF_FORMAT" do
        ENV["EVENT_PROF_FORMAT"] = "simple"

        expect(TestProf::EventProf.config.printer).to eq TestProf::EventProf::Printers::Simple
      end

      it "respects TAG_PROF_FORMAT" do
        ENV["TAG_PROF_FORMAT"] = "html"

        expect(TestProf::TagProf.printer).to eq TestProf::TagProf::Printers::HTML
      end

      it "respects TPS_PROF_FORMAT" do
        ENV["TPS_PROF_FORMAT"] = "text"

        expect(TestProf::TPSProf::Configuration.new.reporter).to be_a TestProf::TPSProf::Reporter::Text
      end
    end
  end

  context "per-profiler variables without the global switch" do
    it "respects FPROF=json" do
      ENV["FPROF"] = "json"

      expect(TestProf::FactoryProf.config.printer).to eq TestProf::FactoryProf::Printers::Json
    end

    it "respects EVENT_PROF_FORMAT=json" do
      ENV["EVENT_PROF_FORMAT"] = "json"

      expect(TestProf::EventProf.config.printer).to eq TestProf::EventProf::Printers::Json
    end

    it "respects TAG_PROF_FORMAT=json" do
      ENV["TAG_PROF_FORMAT"] = "json"

      expect(TestProf::TagProf.printer).to eq TestProf::TagProf::Printers::Json
    end

    it "respects TPS_PROF_FORMAT=json" do
      ENV["TPS_PROF_FORMAT"] = "json"

      expect(TestProf::TPSProf::Configuration.new.reporter).to be_a TestProf::TPSProf::Reporter::Json
    end
  end
end
