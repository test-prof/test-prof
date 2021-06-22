# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require_relative "../../../support/ar_models"
require_relative "../../../support/transactional_minitest"
require "minitest/autorun"

require "test_prof/recipes/minitest/before_all"

class BaseTest < Minitest::Test
  prepend TransactionalMinitest
  include TestProf::BeforeAll::Minitest

  before_all do
    @user = TestProf::FactoryBot.create(:user, name: %w[Matroskin Sharik].sample)
  end
end

class SomeTest < BaseTest
  def setup
    super
    @user = @user.reload
  end

  def test_validates_name
    @user.name = ""
    refute @user.valid?
  end

  def test_clones
    cloned = @user.clone
    cloned.save!
    assert cloned.reload.name.include?("(cloned)")
  end
end

class SomeOtherTest < BaseTest
  before_all do
    @another_user = TestProf::FactoryBot.create(:user, name: %w[Pechkin Fedor].sample)
  end

  def setup
    super
    @user = @user.reload
    @another_user = @another_user.reload
  end

  def test_both_users
    refute_equal @another_user, @user
  end
end
