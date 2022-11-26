# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require_relative "../../../support/ar_models"
require_relative "../../../support/transactional_context"

require "test_prof/recipes/rspec/let_it_be"
require "test_prof/recipes/rspec/factory_default"

describe "Post" do
  let(:post) { TestProf::FactoryBot.create(:post) }

  context "with let_it_be" do
    let_it_be(:user) { TestProf::FactoryBot.create_default(:user) }

    it "creates post with the same user" do
      user
      expect { post }.not_to change(User, :count)
      expect(post.user).to eq user
    end

    it "still uses the default from let_it_be" do
      expect { post }.not_to change(User, :count)
    end

    context "when nested" do
      let_it_be(:post) { TestProf::FactoryBot.create_default(:post) }

      it "still uses the default from let_it_be" do
        expect { post }.not_to change(User, :count)
      end

      it "default is used within let_it_be" do
        expect(post.user).to eq user
      end
    end
  end

  context "without let_it_be" do
    it "creates a new record" do
      expect { post }.to change(User, :count).by(1)
    end
  end
end
