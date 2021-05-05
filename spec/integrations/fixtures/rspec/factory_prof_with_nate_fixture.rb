# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require_relative "../../../support/ar_models"
require "test-prof"

TestProf.configure do |config|
  config.output_dir = "../../../../tmp/test_prof"
end

require "test_prof/factory_prof/nate_heckler"

describe "User" do
  context "created by factory_bot" do
    let(:user) { TestProf::FactoryBot.create(:user) }

    it "generates random names" do
      user2 = TestProf::FactoryBot.create(:user)
      expect(user.name).not_to eq user2.name
    end

    it "creates user with post" do
      expect do
        TestProf::FactoryBot.create(:user, :with_posts, name: "John")
      end.to change(Post, :count).by(2)
    end
  end

  context "created by fabrication" do
    let(:user) { Fabricate(:user) }

    it "generates random names" do
      user2 = Fabricate(:user)
      expect(user.name).not_to eq user2.name
    end

    it "creates user with post" do
      expect do
        Fabricate(:user, name: "John") do
          Fabricate.times(2, :post)
        end
      end.to change(Post, :count).by(2)
    end
  end
end
