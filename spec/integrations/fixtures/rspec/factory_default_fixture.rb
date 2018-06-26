# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require_relative "../../../support/ar_models"
require_relative "../../../support/transactional_context"
require "test_prof/recipes/rspec/factory_default"

describe "Post" do
  let(:user) { TestProf::FactoryBot.create_default(:user) }
  let(:post) { TestProf::FactoryBot.create(:post) }

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
    expect { TestProf::FactoryBot.create_list(:post, 5) }.not_to change(User, :count)
    expect(user.posts.count).to eq 5
  end

  it "works with specified user" do
    user
    user2 = TestProf::FactoryBot.create(:user)
    post = TestProf::FactoryBot.create(:post, user: user2)
    expect(post.user).to eq user2
  end

  context "with redefined user" do
    let(:user2) { TestProf::FactoryBot.create(:user) }

    before { TestProf::FactoryBot.set_factory_default(:user, user2) }

    it "uses redefined default" do
      expect(post.user).to eq user2
    end
  end

  context "with preserved traits" do
    let(:traited_post) { TestProf::FactoryBot.create(:post, :with_traited_user) }
    let(:traited_user) { TestProf::FactoryBot.create_default(:user, :traited, tag: 'foo') }

    context "global setting" do
      before { TestProf::FactoryDefault.preserve_traits = true }

      it "can still be set default" do
        expect(traited_user.tag).to eq 'foo'
        expect(post.user).to eq traited_user
      end

      it "uses different objects for default and for traits" do
        expect {
          user
          post
          expect(post.user).to eq user
          expect(traited_post.user).not_to eq user
          expect(TestProf::FactoryBot.create(:post, :with_traited_user).user).not_to eq traited_post.user
        }.to change(User, :count).by(3)
      end
    end

    context "local override" do
      before { TestProf::FactoryDefault.preserve_traits = false }
      let(:override_user) { TestProf::FactoryBot.create_default(:user, preserve_traits: true) }
      let(:other_traited_post) { TestProf::FactoryBot.create(:post, :with_traited_user) }

      it "uses different objects for default and for traits" do
        expect {
          user
          post
          expect(post.user).to eq user
          expect(traited_post.user).to eq user

          override_user
          expect(other_traited_post.user).not_to eq override_user
          expect(other_traited_post.user).not_to eq traited_post.user
        }.to change(User, :count).by(3)
      end
    end
  end
end
