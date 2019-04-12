# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require_relative "../../../support/ar_models"
require "minitest/autorun"
require "test-prof"

describe "Post" do
  let(:user) { TestProf::FactoryBot.create(:user) }

  it "generates random names" do
    user2 = TestProf::FactoryBot.create(:post).user
    refute_equal user.name, user2.name
  end
end

describe "User" do
  let(:user) { TestProf::FactoryBot.create(:user) }

  it "validates name" do
    user.name = ""
    assert_equal user.valid?, false
  end
end
