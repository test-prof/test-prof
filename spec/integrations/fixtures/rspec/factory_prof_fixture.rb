# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require_relative "../../../support/ar_models"
require "test-prof"

TestProf.configure do |config|
  config.output_dir = "../../../../tmp"
end

describe "User" do
  context "created by factory_girl" do
    let(:user) { FactoryGirl.create(:user) }

    it "generates random names" do
      user2 = FactoryGirl.create(:user)
      expect(user.name).not_to eq user2.name
    end

    it "creates user with post" do
      expect do
        FactoryGirl.create(:user, :with_posts, name: 'John')
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
        Fabricate(:user, name: 'John') do
          Fabricate.times(2, :post)
        end
      end.to change(Post, :count).by(2)
    end
  end
end

describe "Post" do
  context "created by factory_girl" do
    let(:user) { FactoryGirl.create(:user) }

    it "creates posts with users" do
      expect { FactoryGirl.create_pair(:post) }.to change(User, :count).by(2)
    end

    it "creates post with defined user" do
      user
      expect { FactoryGirl.create(:post, user: user) }
        .not_to change(User, :count)
    end
  end

  context "created by fabrication" do
    let(:user) { Fabricate(:user) }

    it "creates posts with users" do
      expect { Fabricate.times(2, :post) }.to change(User, :count).by(2)
    end

    it "creates post with defined user" do
      user
      expect { Fabricate(:post, user: user) }
        .not_to change(User, :count)
    end
  end
end
