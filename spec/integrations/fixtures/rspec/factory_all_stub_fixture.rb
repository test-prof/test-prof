# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require_relative "../../../support/ar_models"
require_relative "../../../support/transactional_context"
require "test_prof/recipes/rspec/factory_all_stub"

RSpec.configure do |config|
  config.include TestProf::FactoryBot::Syntax::Methods
end

describe "User", :transactional, factory: :stub do
  let(:user) { TestProf::FactoryBot.create(:user) }

  it "works with create" do
    expect do
      user2 = TestProf::FactoryBot.create(:user)
      expect(user.name).not_to eq user2.name
    end.not_to change(User, :count)
  end

  context "with disabled stub" do
    around do |ex|
      TestProf::FactoryAllStub.disable!
      ex.run
      TestProf::FactoryAllStub.enable!
    end

    it "validates name" do
      user.name = ""
      expect(user).not_to be_valid
    end
  end

  it "works with build" do
    expect do
      build(:post, :with_bad_user)
    end.not_to change(User, :count)
  end
end
