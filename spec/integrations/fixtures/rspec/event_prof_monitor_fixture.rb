# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require "active_support"
require "test-prof"

TestProf::EventProf.configure do |config|
  config.per_example = true
  config.rank_by = :count
end

class Work
  def one
    true
  end

  def two
    false
  end
end

TestProf::EventProf.monitor(Work, "test.event", :one, :two)

describe "Work" do
  let(:w) { Work.new }
  it "invokes once" do
    expect(w.one).to eq true
  end

  it "invokes twice" do
    expect(w.one && w.two).to eq false
  end
end
