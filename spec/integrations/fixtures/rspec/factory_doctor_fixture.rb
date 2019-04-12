# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require_relative "../../../support/ar_models"
require "test-prof"

describe "User" do
  let(:user) { TestProf::FactoryBot.create(:user) }

  it "generates random names" do
    user2 = TestProf::FactoryBot.create(:user)
    expect(user.name).not_to eq user2.name
  end

  it "validates name" do
    user.name = ""
    expect(user).not_to be_valid
  end

  it "creates and reloads user" do
    user = TestProf::FactoryBot.create(:user, name: "John")
    expect(User.find(user.id).name).to eq "John"
  end

  it "clones" do
    expect(user.clone.name).to include("(cloned)")
  end

  it "is ignored", :fd_ignore do
    user.name = ""
    expect(user).not_to be_valid
  end
end
