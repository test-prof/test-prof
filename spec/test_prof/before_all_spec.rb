# frozen_string_literal: true

require "test_prof/before_all"

RSpec.describe TestProf::BeforeAll do
  let(:adapter) { double("Adapter") }

  before do
    described_class.adapter = adapter
  end

  describe ".adapter" do
    context "when adapter is set" do
      it "returns the adapter" do
        expect(described_class.adapter).to eq(adapter)
      end
    end

    context "when adapter is not set" do
      before do
        described_class.adapter = nil
      end

      let(:dry_run) { false }

      before do
        allow(TestProf).to receive(:dry_run?).and_return(dry_run)
      end

      it "returns the ActiveRecord adapter" do
        expect(described_class.adapter).to eq(TestProf::BeforeAll::Adapters::ActiveRecord)
      end

      context "when dry run mode is enabled" do
        let(:dry_run) { true }

        it "returns NoopAdapter" do
          expect(described_class.adapter).to eq(TestProf::BeforeAll::NoopAdapter)
        end
      end
    end
  end

  describe ".begin_transaction" do
    it "calls begin_transaction on adapter" do
      allow(adapter).to receive(:begin_transaction)
      expect(adapter).to receive(:begin_transaction)

      described_class.begin_transaction {}
    end
  end

  describe ".rollback_transaction" do
    it "calls rollback_transaction on adapter" do
      allow(adapter).to receive(:rollback_transaction)
      expect(adapter).to receive(:rollback_transaction)

      described_class.rollback_transaction {}
    end
  end

  describe ".setup_fixtures" do
    context "when adapter supports setup_fixtures" do
      it "calls setup_fixtures on adapter" do
        test_object = double("TestObject")
        allow(adapter).to receive(:setup_fixtures)
        expect(adapter).to receive(:setup_fixtures).with(test_object)

        described_class.setup_fixtures(test_object)
      end
    end

    context "when adapter does not support setup_fixtures" do
      it "raises ArgumentError" do
        allow(adapter).to receive(:respond_to?).with(:setup_fixtures).and_return(false)

        expect { described_class.setup_fixtures(double("TestObject")) }.to raise_error(ArgumentError, "Current adapter doesn't support #setup_fixtures")
      end
    end
  end
end

describe TestProf::BeforeAll::Configuration do
  let(:config) { described_class.new }

  describe "#before" do
    it "adds a before hook to the specified type" do
      block = proc {}
      config.before(:begin, &block)

      expect(config.instance_variable_get(:@hooks)[:begin].before.map(&:block)).to include(block)
    end

    it "raises an error for invalid hook type" do
      expect { config.before(:invalid_type) {} }.to raise_error(ArgumentError, "Unknown hook type: invalid_type. Valid types: begin, rollback")
    end
  end

  describe "#after" do
    it "adds an after hook to the specified type" do
      block = proc {}
      config.after(:rollback, &block)

      expect(config.instance_variable_get(:@hooks)[:rollback].after.map(&:block)).to include(block)
    end

    it "raises an error for invalid hook type" do
      expect { config.after(:invalid_type) {} }.to raise_error(ArgumentError, "Unknown hook type: invalid_type. Valid types: begin, rollback")
    end
  end

  describe "#run_hooks" do
    it "runs all before and after hooks for the specified type" do
      block_before = proc {}
      block_after = proc {}

      config.before(:begin, &block_before)
      config.after(:begin, &block_after)

      expect(block_before).to receive(:call).once
      expect(block_after).to receive(:call).once

      config.run_hooks(:begin) {}
    end

    it "raises an error for invalid hook type" do
      expect { config.run_hooks(:invalid_type) {} }.to raise_error(ArgumentError, "Unknown hook type: invalid_type. Valid types: begin, rollback")
    end
  end
end
