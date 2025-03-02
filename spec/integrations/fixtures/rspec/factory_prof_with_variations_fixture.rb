# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require_relative "../../../support/ar_models"
require "test-prof"

TestProf.configure do |config|
  config.output_dir = "../../../../tmp/test_prof"
end

describe "User" do
  context "created by factory_bot" do
    context "with few traits" do
      let!(:user_with_traits) { TestProf::FactoryBot.create(:user, :traited, :with_posts) }
      let!(:user_with_same_traits) { TestProf::FactoryBot.create(:user, :with_posts, :traited) }

      it "works" do
        expect(true).to eq true
      end
    end

    context "with many traits" do
      let!(:user_over_limit) { TestProf::FactoryBot.create(:user, :with_posts, :traited, :other_trait, tag: "tag") }
      let!(:another_user_over_limit) { TestProf::FactoryBot.create(:user, :with_posts, :traited, tag: "some tag") }

      it "works" do
        expect(true).to eq true
      end
    end
  end

  context "created by fabrication" do
    let!(:user) { Fabricate(:user) }
    let!(:another_user_1) { Fabricate(:user, name: "some name") }
    let!(:another_user_2) { Fabricate(:user, name: "some name") }
    let!(:post) { Fabricate(:post, user: user, text: "some text") }
    let!(:post_with_same_overrides) { Fabricate(:post, text: "some text", user: user) }

    it "works" do
      expect(true).to eq true
    end
  end
end

describe "Supercalifragilisticexpialidocious" do
  let(:factory) { :supercalifragilisticexpialidocious }
  let(:trait) { :other_trait_with_very_long_name }
  let(:other_trait) { :traited }

  context "created by factory_bot" do
    context "with few traits" do
      let!(:user_with_traits) { TestProf::FactoryBot.create(factory, trait) }
      let!(:user_with_same_traits) { TestProf::FactoryBot.create(factory, trait) }

      it "works" do
        expect(true).to eq true
      end
    end

    context "with many traits" do
      let!(:user_over_limit) { TestProf::FactoryBot.create(factory, trait, other_trait, tag: "tag") }
      let!(:another_user_over_limit) { TestProf::FactoryBot.create(factory, other_trait, tag: "some tag") }

      it "works" do
        expect(true).to eq true
      end
    end
  end
end
