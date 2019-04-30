# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require_relative "../../../support/ar_models"
require_relative "../../../support/transactional_context"
require "test_prof/recipes/rspec/before_all"
# for threading tests
require "test_prof/recipes/active_record_one_love" if ::ActiveRecord::VERSION::MAJOR < 5 || defined?(JRUBY_VERSION)

module Events
  class << self
    def events
      @events ||= []
    end

    def add_event(event)
      events << event
    end
  end
end

RSpec.configure do |config|
  config.before(:each) do
    Events.add_event :before_each
  end
end

TestProf::BeforeAll.configure do |config|
  config.setup_before_all do
    Events.add_event :setup_before_all
  end
end

describe "A test suite" do
  context "without before_all" do
    after(:all) { Events.events.clear }

    it "should not setup before_all" do
      expect(Events.events).to eq([:before_each])
    end
  end

  context "with before_all" do
    before_all { Events.add_event :before_all }
    after(:all) { Events.events.clear }

    it "should setup before_all" do
      expect(Events.events).to eq([:setup_before_all, :before_all, :before_each])
    end
  end

  context "with before_all" do
    before_all { Events.add_event :before_all_parent }

    context "with nested before_all" do
      before_all { Events.add_event :before_all_child }
      after(:all) { Events.events.clear }

      it "should setup before_all twice" do
        expect(Events.events).to eq([
          :setup_before_all,
          :before_all_parent,
          :setup_before_all,
          :before_all_child,
          :before_each
        ])
      end
    end
  end
end
