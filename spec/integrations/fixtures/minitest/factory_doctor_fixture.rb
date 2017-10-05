# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require_relative "../../../support/ar_models"
require 'minitest/autorun'
require "test-prof"

describe "User" do
  before do
    @user = FactoryGirl.create(:user)
  end

  it "generates random names" do
    user2 = FactoryGirl.create(:user)
    refute_equal @user.name, user2.name
  end

  it "validates name" do
    @user.name = ''
    refute @user.valid?
  end

  it "creates and reloads user" do
    @user = FactoryGirl.create(:user, name: 'John')
    assert User.find(@user.id).name, 'John'
  end

  it "clones" do
    assert @user.clone.name.include?('cloned')
  end

  # TODO: Rewrite when suitable solution for ignoring examples in Minitest
  # will be discussed
 
  # it "is ignored", :fd_ignore do
  #   user.name = ''
  #   expect(user).not_to be_valid
  # end
end
