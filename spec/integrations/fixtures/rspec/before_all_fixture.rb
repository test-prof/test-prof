# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require_relative "../../../support/ar_models"
require_relative "../../../support/transactional_context"
require "test_prof/recipes/rspec/before_all"

describe "User", :transactional do
  context "with before_all" do
    before_all do
      @user = FactoryGirl.create(:user)
    end

    let(:user) { User.find(@user.id) }

    it "validates name" do
      user.name = ''
      expect(user).not_to be_valid
    end

    it "clones" do
      cloned = user.clone
      cloned.save!
      expect(cloned.reload.name).to include("(cloned)")
    end
  end

  context "without before_all" do
    specify "no users" do
      expect(User.count).to eq 0
    end
  end
end
