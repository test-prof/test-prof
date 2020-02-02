# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require_relative "../../../support/ar_models"
require_relative "../../../support/transactional_context"

shared_context "with user" do
  let_it_be(:context_user) { create(:user, name: "Lolo") }
end

RSpec.configure do |config|
  config.include_context "with user", with_user: true
end

require "test_prof/recipes/rspec/let_it_be"

RSpec.configure do |config|
  config.include TestProf::FactoryBot::Syntax::Methods
end

TestProf::LetItBe.configure do |config|
  config.register_modifier :touch_with_shift do |target, shift = 0|
    next target unless target.respond_to?(:created_at)

    shift = 0 if shift == true

    target.created_at = Time.current + shift.hours
    target
  end

  config.alias_to :let_with_refind, refind: true
end

describe "User", :transactional do
  before(:all) do
    @cache = {}
  end

  context "with let_it_be" do
    let_it_be(:user) { create(:user) }

    before(:all) { @cache[:user_name] = user.name }

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
        user.name = ""
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
        user.name = ""
        expect(user).not_to be_valid
      end

      it "is valid" do
        expect(user).to be_valid
      end
    end

    context "with arrays", order: :defined do
      let_it_be(:posts, refind: true) { create_pair(:post) }

      it "returns array" do
        posts.first.dirty = true
        expect(posts.size).to eq 2
      end

      it "refinds items" do
        expect(posts.any?(&:dirty)).to eq false
      end
    end

    context "with custom modifier" do
      let_it_be(:post, touch_with_shift: true) { create(:post, created_at: 1.day.ago) }
      let_it_be(:post2, touch_with_shift: 2) { create(:post, created_at: 1.day.ago) }

      it "applies custom modifier" do
        expect(post.created_at).to be >= 1.hour.ago
        expect(post2.created_at).to be >= (Time.current + 1.hour)
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
      @user.name = ""
      expect(user.name).to eq ""
      expect(user).not_to be_valid
    end

    it "is valid" do
      expect(user).to be_valid
    end

    specify { expect(User.count).to eq 1 }
  end

  context "with aliased let_it_be used to default refind to true" do
    let_with_refind(:user) { @user = create(:user) }

    it "should refind" do
      expect(@user).to eq(user)
      expect(@user.object_id).not_to eq(user.object_id)
    end
  end

  context "with aliased let_it_be used to default refind to true but overridden" do
    let_with_refind(:user, refind: false) { @user = create(:user) }

    it "should not refind" do
      expect(@user).to eq(user)
      expect(@user.object_id).to eq(user.object_id)
    end
  end

  context "without let_it_be" do
    specify { expect(User.count).to eq 0 }
  end
end

describe "User", :transactional do
  context "with shared context" do
    it "works", :with_user do
      expect(User.where(name: "Lolo").count).to eq 1
    end
  end
end
