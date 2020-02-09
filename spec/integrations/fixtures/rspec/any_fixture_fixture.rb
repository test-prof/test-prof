# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require_relative "../../../support/ar_models"
require_relative "../../../support/transactional_context"
require "test_prof/recipes/rspec/any_fixture"

require "test_prof/any_fixture/dsl"
using TestProf::AnyFixture::DSL

shared_context "user", user: true do
  before(:all) do
    @user = fixture(:user) do
      TestProf::FactoryBot.create(:user)
    end
  end

  let(:user) { User.find(fixture(:user).id) }
end

describe "User", :user do
  it "creates user" do
    user.name = ""
    expect(user).not_to be_valid
  end

  context "with clean fixture", :transactional do
    specify "no users", :with_clean_fixture do
      expect(User.count).to eq 0
    end
  end
end

describe "Post", :user, :transactional do
  let(:post) { TestProf::FactoryBot.create(:post, user: user) }
  after { post.destroy }

  it "creates post with the same user" do
    expect { post }.not_to change(User, :count)
  end

  context "with fixture post" do
    before(:all) { fixture(:post) { TestProf::FactoryBot.create(:post) } }

    let(:post) { fixture(:post) }

    it "creates post with another user" do
      expect(post.user).not_to eq user
    end
  end
end

describe "Without AnyFixture" do
  it "works" do
    expect(true).to eq true
  end
end
