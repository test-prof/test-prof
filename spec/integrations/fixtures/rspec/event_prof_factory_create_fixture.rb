# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require_relative "../../../support/ar_models"
require "test-prof"

describe "Post" do
  let(:user) { FactoryGirl.create(:user) }

  it "generates random names" do
    user2 = FactoryGirl.create(:post).user
    expect(user.name).not_to eq user2.name
  end
end

describe "User" do
  let(:user) { FactoryGirl.create(:user) }

  it "validates name" do
    user.name = ''
    expect(user).not_to be_valid
  end
end
