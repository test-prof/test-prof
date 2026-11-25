# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require "active_support"
require "active_support/notifications"
require "factory_bot"
require "test-prof"

# Running a top-level monitored event (such as `factory.create`) on a thread
# other than the thread where the monitor was initialized must not crash
# EventProf. TopLevelTracker previously seeded its thread-local depth counter
# only in `#initialize`, so calling `#track` on another thread raised
# `NoMethodError: undefined method '+' for nil`.
class CrossThreadWidget
  attr_accessor :name, :parent

  def save!
    true
  end
end

FactoryBot.define do
  factory :cross_thread_widget, class: "CrossThreadWidget" do
    name { "widget" }

    trait :with_parent do
      parent { create(:cross_thread_widget, name: "parent") }
    end
  end
end

describe "EventProf factory.create across threads" do
  it "creates on the example thread" do
    widget = FactoryBot.create(:cross_thread_widget)
    expect(widget.name).to eq "widget"
  end

  it "creates on another thread" do
    widget = Thread.new { FactoryBot.create(:cross_thread_widget, :with_parent) }.value
    expect(widget.name).to eq "widget"
    expect(widget.parent.name).to eq "parent"
  end
end
