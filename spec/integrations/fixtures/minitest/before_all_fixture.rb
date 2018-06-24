# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require_relative "../../../support/ar_models"
require_relative "../../../support/transactional_minitest"
require "minitest/autorun"

require "test_prof/recipes/minitest/before_all"

describe "User" do
  include TestProf::BeforeAll::Minitest
  prepend TransactionalMinitest

  before_all do
    @user = TestProf::FactoryBot.create(:user)
  end

  def setup
    @user = @user.reload
  end

  it "validates name" do
    @user.name = ''
    refute @user.valid?
  end

  it "clones" do
    cloned = @user.clone
    cloned.save!
    assert cloned.reload.name.include?("(cloned)")
  end
end

describe "without before_all" do
  it "no users" do
    assert_equal 0, User.count
  end
end
