# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require_relative "../../../support/ar_models"
require_relative "../../../support/transactional_context"
require "test_prof/recipes/rspec/factory_default"

describe "Post" do
  let(:user) { TestProf::FactoryBot.create(:user) }
  let(:post) { TestProf::FactoryBot.create(:post) }

  it "creates post with different user" do
    user
    expect { post }.to change(User, :count)
    expect(post.user).not_to eq user
  end

  it "creates user if no default" do
    expect { post }.to change(User, :count).by(1)
  end

  it "creates many records" do
    user
    expect { TestProf::FactoryBot.create_list(:post, 5) }.to change(User, :count).by(5)
  end

  context "with traits" do
    let(:post) { TestProf::FactoryBot.create(:post, :with_traited_user) }

    it "can still be set default" do
      expect(post.user.tag).to eq "traited"
    end
  end

  context "with overrides" do
    let(:post) { TestProf::FactoryBot.create(:post, :with_tagged_user) }

    it "can still be set default" do
      expect(post.user.tag).to eq "some tag"
    end
  end
end
