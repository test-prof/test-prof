# frozen_string_literal: true

require_relative "../../../support/ar_models"
require_relative "../../../support/transactional_context"

require "test_prof/recipes/rspec/let_it_be"

RSpec.configure do |config|
  config.include TestProf::FactoryBot::Syntax::Methods
end

TestProf::LetItBe.configure do |config|
  config.default_modifiers[:refind] = true
end

RSpec.describe "Post", :transactional do
  let_it_be(:post) { @post = create(:post) }

  let(:user) { post.user }

  it "validates name" do
    user.name = ""
    expect(user).not_to be_valid
  end

  it "is valid" do
    expect(user).to be_valid
  end

  it "should refind" do
    expect(@post.user).to eq(user)
    expect(@post.user.object_id).not_to eq(user.object_id)
  end

  context "with modifier override", order: :defined do
    let_it_be(:user, refind: false) { create(:user) }

    it "validates name" do
      user.name = ""
      expect(user).not_to be_valid
    end

    it "is not valid" do
      expect(user).not_to be_valid
    end
  end

  context "with modifier override via metadata", let_it_be_modifiers: {refind: false}, order: :defined do
    let_it_be(:user) { @user = create(:user) }

    it "validates name" do
      user.name = ""
      expect(user).not_to be_valid
    end

    it "is not valid" do
      expect(user).not_to be_valid
    end

    context "with overrides", let_it_be_modifiers: {reload: true} do
      let_it_be(:user, refind: false) { @user = create(:user) }
      let_it_be(:user2, reload: false, refind: true) { @user2 = create(:user) }

      it "validates name" do
        user.name = ""
        user2.name = ""

        expect(user).not_to be_valid
        expect(user2).not_to be_valid
      end

      it "is valid" do
        expect(user).to be_valid
        expect(user2).to be_valid
      end

      it "has object_id" do
        expect(@user.object_id).to eq(user.object_id)
        expect(@user2.object_id).not_to eq(user2.object_id)
      end
    end
  end
end
