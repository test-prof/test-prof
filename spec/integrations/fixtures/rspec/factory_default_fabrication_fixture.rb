# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require_relative "../../../support/ar_models"
require_relative "../../../support/transactional_context"
require "test_prof/recipes/rspec/factory_default"

TestProf::FactoryDefault.configure do |config|
  config.preserve_attributes = true
end

describe "Post" do
  let(:user) { Fabricate.create_default(:user) }
  let(:post) { Fabricate(:post) }

  it "creates post with the same user" do
    user
    expect { post }.not_to change(User, :count)
    expect(post.user).to eq user
  end

  it "creates associated user if no default" do
    expect { post }.to change(User, :count).by(1)
  end

  it "creates new user if not an association" do
    user
    expect { Fabricate(:user) }.to change(User, :count).by(1)
  end

  it "works with many records" do
    user
    expect { Fabricate.times(5, :post) }.not_to change(User, :count)
    expect(user.posts.count).to eq 5
  end

  it "works with specified user" do
    user
    user2 = Fabricate(:user)
    post = Fabricate(:post, user: user2)
    expect(post.user).to eq user2
  end

  context "with redefined user" do
    let(:user2) { Fabricate(:user) }

    before { Fabricate.set_fabricate_default(:user, user2) }

    it "uses redefined default" do
      expect(post.user).to eq user2
    end
  end

  context "with overrides" do
    before { user }

    it "creates new record if overrides do not match" do
      expect { Fabricate(:alice_post) }.to change(User, :count).by(1)
    end
  end
end
