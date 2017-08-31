# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require_relative "../../../support/ar_models"
require_relative "../../../support/transactional_context"
require "test_prof/recipes/rspec/factory_default"

describe "Post" do
  let(:user) { FactoryGirl.create_default(:user) }
  let(:post) { FactoryGirl.create(:post) }

  it "creates post with the same user" do
    user
    expect { post }.not_to change(User, :count)
    expect(post.user).to eq user
  end

  it "creates user if no default" do
    expect { post }.to change(User, :count).by(1)
  end

  it "works with many records" do
    user
    expect { FactoryGirl.create_list(:post, 5) }.not_to change(User, :count)
    expect(user.posts.count).to eq 5
  end

  it "works with specified user" do
    user
    user2 = FactoryGirl.create(:user)
    post = FactoryGirl.create(:post, user: user2)
    expect(post.user).to eq user2
  end

  context "with redefined user" do
    let(:user2) { FactoryGirl.create(:user) }

    before { FactoryGirl.set_factory_default(:user, user2) }

    it "uses redefined default" do
      expect(post.user).to eq user2
    end
  end
end
