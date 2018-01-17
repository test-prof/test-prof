# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require_relative "../../../support/ar_models"
require 'minitest/autorun'
require "test-prof"

describe "User" do
  before do
    @user = TestProf::FactoryBot.create(:user)
  end

  it "generates random names" do
    user2 = TestProf::FactoryBot.create(:user)
    refute_equal @user.name, user2.name
  end

  it "validates name" do
    @user.name = ''
    refute @user.valid?
  end

  it "creates and reloads user" do
    @user = TestProf::FactoryBot.create(:user, name: 'John')
    assert User.find(@user.id).name, 'John'
  end

  it "clones" do
    assert @user.clone.name.include?('cloned')
  end

  it "is ignored" do
    fd_ignore

    @user.name = ''
    refute @user.valid?
  end
end

class PlainMinitest < Minitest::Test
  def setup
    @user = TestProf::FactoryBot.create(:user)
  end

  def test_factory_doctor
    @user.name = ''
    refute @user.valid?
  end
end
