# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require_relative "../../../support/ar_models"
require "test-prof"

module Rails
  class << self
    attr_writer :logger

    def logger
      @logger ||= Logger.new(IO::NULL)
    end
  end
end

require "test_prof/recipes/logging"

TestProf.configure do |config|
  config.output_dir = "../../../../tmp/test_prof"
end

describe "Logging" do
  context "global", test: :global do
    context "ActiveRecord" do
      let(:user) { TestProf::FactoryBot.create(:user) }

      it "generates users" do
        user2 = TestProf::FactoryBot.create(:user, name: "a")
        Rails.logger.debug "USER: #{user2.name}"
        expect(user.name).not_to eq user2.name
      end
    end

    context "all" do
      let(:user) { TestProf::FactoryBot.create(:user) }

      it "generates users" do
        user2 = TestProf::FactoryBot.create(:user, name: "b")
        Rails.logger.debug "USER: #{user2.name}"
        expect(user.name).not_to eq user2.name
      end
    end
  end

  context "tags", test: :tags do
    context "tags active_record", log: :ar do
      let(:user) { Fabricate(:user) }

      it "generates users" do
        user2 = Fabricate(:user, name: "invisible")
        Rails.logger.debug "USER: #{user2.name}"
        expect(user.name).not_to eq user2.name
      end
    end

    context "tags all", log: :all do
      let(:user) { Fabricate(:user) }

      it "generates users" do
        user2 = Fabricate(:user, name: "visible")
        Rails.logger.debug "USER: #{user2.name}"
        expect(user.name).not_to eq user2.name
      end
    end
  end
end
