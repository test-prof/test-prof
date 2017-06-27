# frozen_string_literal: true

require "spec_helper"
require "test_prof/rspec_stamp/parser"

describe TestProf::RSpecStamp::Parser do
  subject { described_class }

  describe ".parse" do
    it "handles simple expr" do
      res = subject.parse('it "works"')
      expect(res.fname).to eq 'it'
      expect(res.desc).to eq 'works'
      expect(res.tags).to be_nil
      expect(res.htags).to be_nil
    end

    it "handles missing desc" do
      res = subject.parse('it ')
      expect(res.fname).to eq 'it'
      expect(res.desc).to be_nil
      expect(res.tags).to be_nil
      expect(res.htags).to be_nil
    end

    it "handles parentheses" do
      res = subject.parse('    it("is") ')
      expect(res.fname).to eq 'it'
      expect(res.desc).to eq 'is'
      expect(res.tags).to be_nil
      expect(res.htags).to be_nil
    end

    it "handles several args" do
      res = subject.parse('  it "is o\'h", :cool, :bad ')
      expect(res.fname).to eq 'it'
      expect(res.desc).to eq "is o'h"
      expect(res.tags).to eq(%i[cool bad])
      expect(res.htags).to be_nil
    end

    it "handles hargs" do
      res = subject.parse('  it "is", cool: :bad, type: "feature" ')
      expect(res.fname).to eq 'it'
      expect(res.desc).to eq "is"
      expect(res.tags).to be_nil
      expect(res.htags).to eq([%i[cool bad], [:type, "feature"]])
    end

    it "handles args and hargs" do
      res = subject.parse('  it "is", :cool, :bad, type: :feature ')
      expect(res.fname).to eq 'it'
      expect(res.desc).to eq "is"
      expect(res.tags).to eq(%i[cool bad])
      expect(res.htags).to eq([%i[type feature]])
    end
  end
end
