# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require_relative "../../../support/ar_models"
require "test_prof/recipes/rspec/any_fixture"

require "test_prof/any_fixture/dsl"
using TestProf::AnyFixture::DSL

shared_context "user_and_post", user_and_post: true do
  before(:all) do
    @user = fixture(:user) do
      TestProf::FactoryBot.create(:user)
    end
  end

  before { TestProf::FactoryBot.create(:post) }

  let(:user) { User.find(fixture(:user).id) }
end

describe "before_fixtures_reset callback", :user_and_post do
  before(:all) do
    before_fixtures_reset do
      Post.delete_all
    end
  end

  it "deletes post" do
    expect { TestProf::AnyFixture.reset }.to change(Post, :count).by(-1)
  end
end

describe "after_fixtures_reset callback", :user_and_post do
  before(:all) do
    after_fixtures_reset do
      Post.delete_all
    end
  end

  it "deletes post" do
    expect { TestProf::AnyFixture.reset }.to change(Post, :count).by(-1)
  end
end

describe "without callbacks", :user_and_post do
  before { TestProf::FactoryBot.create(:post) }
  after { Post.delete_all }

  it "doesn't delete post" do
    expect { TestProf::AnyFixture.reset }.not_to change(Post, :count)
  end
end
