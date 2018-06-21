# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../../lib", __FILE__)

require "test-prof"

class Work
  attr_reader :runned

  def initialize(val = 0.1)
    @value = val
    sleep(@value)
  end

  def run
    return false if @runned
    sleep @value
    @runned = true
  end
end

describe "Subject + Before" do
  subject(:work) { Work.new }
  let(:no_work) { Work.new }

  specify do
    expect(no_work).not_to be_nil
  end

  it "does nothing" do
    expect(true).to eq true
  end

  context "with before" do
    before { work.run }

    specify do
      expect(work.runned).to eq true
    end
  end
end

describe "Only let" do
  let(:work) { Work.new }
  let(:more_work) { Work.new(1) }

  it "does nothing" do
    expect(true).to eq true
  end

  it "takes very long" do
    expect(work).not_to eq more_work
  end
end
