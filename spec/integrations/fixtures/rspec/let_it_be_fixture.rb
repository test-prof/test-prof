# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require_relative "../../../support/ar_models"
require_relative "../../../support/transactional_context"
require "test_prof/recipes/rspec/let_it_be"

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end

describe "User", :transactional do
  before(:all) do
    @cache = {}
  end

  context "with let_it_be" do
    let_it_be(:user) { create(:user) }

    it "has name" do
      @cache[:user_name] = user.name
      expect(user).to respond_to(:name)
    end

    it "is cached" do
      expect(user.name).to eq @cache[:user_name]
    end

    context "when let is re-defined" do
      let(:user) { build(:user) }

      it "is not cached" do
        expect(user.name).not_to eq @cache[:user_name]
      end
    end

    context "with reload option" do
      let_it_be(:user, reload: true) { create(:user) }

      it "creates new instance when nested" do
        @cache[:nested_user_name] = user.name
        expect(user.name).not_to eq(@cache[:user_name])
      end

      it "validates name" do
        user.name = ''
        expect(user).not_to be_valid
      end

      it "is valid" do
        expect(user).to be_valid
      end

      context "nested without overwrite" do
        it "is cached" do
          expect(user.name).to eq @cache[:nested_user_name]
        end
      end

      context "total count" do
        specify { expect(User.count).to eq 2 }
      end
    end

    context "multiple definitions" do
      let_it_be(:post) { create(:post, user: user) }

      it "recognizes another definition" do
        expect(post.user.name).to eq @cache[:user_name]
      end
    end

    context "with refind option" do
      let_it_be(:post, refind: true) { create(:post) }

      let(:user) { post.user }

      it "validates name" do
        user.name = ''
        expect(user).not_to be_valid
      end

      it "is valid" do
        expect(user).to be_valid
      end
    end

    context "it still the same" do
      specify do
        expect(user.name).to eq @cache[:user_name]
      end
    end
  end

  context "with instance variable as alias" do
    before(:all) { @user = create(:user) }
    after(:all) { @user.delete }

    let_it_be(:user, reload: true) { @user }

    let_it_be(:post) { create(:post, user: user) }

    specify do
      expect(post.user).to eq @user
    end

    it "creates let-like method" do
      expect(user).to eq @user
      @user.name = ''
      expect(user.name).to eq ''
      expect(user).not_to be_valid
    end

    it "is valid" do
      expect(user).to be_valid
    end

    specify { expect(User.count).to eq 1 }
  end

  context "without let_it_be" do
    specify { expect(User.count).to eq 0 }
  end
end
