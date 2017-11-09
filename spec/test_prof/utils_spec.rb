# frozen_string_literal: true

require "spec_helper"
require "test_prof"

describe TestProf::Utils do
  subject { described_class }

  describe ".verify_gem_version" do
    let(:gem_version) { Gem::Version.new('1.9.89') }
    let(:spec_double) { double('spec', version: gem_version) }
    let(:specs) { { 'abc' => spec_double } }

    before do
      allow(Gem).to receive(:loaded_specs).and_return(specs)
    end

    it "raises when not enough args" do
      expect { described_class.verify_gem_version('abc') }
        .to raise_error(ArgumentError)
    end

    it 'handles unexpected gem name' do
      expect(described_class.verify_gem_version('unexpected-gem-name', at_least: '0')).to eq false
    end

    it "verifies with at_least" do
      expect(described_class.verify_gem_version('abc', at_least: '0.12.100')).to eq true
      expect(described_class.verify_gem_version('abc', at_least: '1.9.100')).to eq false
      expect(described_class.verify_gem_version('abc', at_least: '2.0.0')).to eq false
      expect(described_class.verify_gem_version('abc', at_least: '1.9.89')).to eq true
    end

    it "verifies with at_most" do
      expect(described_class.verify_gem_version('abc', at_most: '0.12.100')).to eq false
      expect(described_class.verify_gem_version('abc', at_most: '1.9.100')).to eq true
      expect(described_class.verify_gem_version('abc', at_most: '2.0.0')).to eq true
      expect(described_class.verify_gem_version('abc', at_most: '1.9.89')).to eq true
    end

    it "verifies with at_most and at_least" do
      expect(described_class.verify_gem_version('abc', at_least: '0.12.100', at_most: '1.0.0')).to eq false
      expect(described_class.verify_gem_version('abc', at_least: '1.9.88', at_most: '1.9.100')).to eq true
      expect(described_class.verify_gem_version('abc', at_least: '0.1.0', at_most: '1.0.0')).to eq false
    end
  end
end
