# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)

require "action_controller/railtie"
require "action_view/railtie"
require "active_record/railtie"
require "rspec/rails"

require_relative "../../../support/ar_models"
require_relative "../../../support/transactional_context"
require "test_prof/recipes/rspec/before_all"
require "test_prof/recipes/rspec/let_it_be"

RSpec.configure do |config|
  config.fixture_path = File.join(__dir__, "fixtures")
end

TestProf::BeforeAll.configure do |config|
  config.setup_fixtures = true
end

describe "Post", :transactional do
  fixtures :users

  context "with before_all" do
    before_all do
      @post = TestProf::FactoryBot.create(:post, text: "Test fixtures", user: users(:vova))
    end

    let(:post) { Post.find(@post.id) }

    it "text and user" do
      expect(post.user).not_to be_nil
      post.text = ""
      post.user_id = nil
      post.save!
      expect(post.reload.text).to be_empty
      expect(post.user).to be_nil
    end

    it "old text and user" do
      expect(post.text).to eq "Test fixtures"
      expect(post.user.name).to eq "Vova"
    end
  end

  context "without before_all" do
    specify "no posts" do
      expect(Post.count).to eq 0
    end
  end
end
