# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require "active_support"
require "sidekiq/testing"

Sidekiq::Testing.inline!

class SingleJob
  include Sidekiq::Worker

  def perform(*_args)
    true
  end
end

class BatchJob
  include Sidekiq::Worker

  def perform(count)
    count.times { SingleJob.perform_async(true) }
  end
end

require "test-prof"

describe "SingleJob" do
  it "invokes once" do
    SingleJob.perform_async(1)
    expect(true).to eq true
  end

  it "invokes twice" do
    SingleJob.perform_async(2)
    expect(true).to eq true
  end
end

describe "BatchJob" do
  it "invokes nested" do
    BatchJob.perform_async(3)
    expect(true).to eq true
  end

  context "when fake" do
    it "is fake" do
      Sidekiq::Testing.fake! do
        BatchJob.perform_async(3)
      end
      expect(true).to eq true
    end
  end
end
