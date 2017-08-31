# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require_relative "../../../support/ar_models"
require_relative "../../../support/transactional_context"
require "test_prof/recipes/rspec/any_fixture"

shared_context "user", user: true do
  before(:all) do
    @user = TestProf::AnyFixture.register(:user) do
      FactoryGirl.create(:user)
    end
  end

  let(:user) { User.find(@user.id) }
end

describe "User", :user do
  it "creates user" do
    user.name = ''
    expect(user).not_to be_valid
  end

  context "with clean fixture", :transactional, :with_clean_fixture do
    specify "no users" do
      expect(User.count).to eq 0
    end
  end
end

describe "Post", :user do
  let(:post) { FactoryGirl.create(:post, user: user) }
  after { post.destroy }

  it "creates post with the same user" do
    expect { post }.not_to change(User, :count)
  end
end
