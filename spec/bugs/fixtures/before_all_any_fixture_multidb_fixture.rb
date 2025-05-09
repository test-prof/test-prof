# frozen_string_literal: true

require "action_controller/railtie"
require "action_view/railtie"
require "active_record/railtie"
require "rspec/rails"

require_relative "../../support/ar_models"

RSpec.configure do |config|
  if config.respond_to?(:fixture_paths)
    config.fixture_paths = [File.join(__dir__, "fixtures")]
  else
    config.fixture_path = File.join(__dir__, "fixtures")
  end
  config.use_transactional_fixtures = true
end

require "test_prof/recipes/rspec/before_all"
require "test_prof/recipes/rspec/let_it_be"
require "test_prof/recipes/rspec/any_fixture"

RSpec.configure do |config|
  config.include TestProf::FactoryBot::Syntax::Methods

  config.before(:suite) do
    TestProf::AnyFixture.register(:user) { TestProf::FactoryBot.create(:user) }
  end
end

# ActiveSupport::Notifications.subscribe("transaction.active_record") do |event|
#   puts "[TRANSACTION] #{event.payload[:outcome].upcase} #{event.payload[:connection].inspect} from: #{caller_locations.find { |l| l.to_s.include?(Rails.root.to_s) }&.to_s}"
# end

# TestProf::BeforeAll.configure do |config|
#   config.before(:begin) do
#     puts "[BEFORE_ALL] connection pools #{::ActiveRecord::Base.connection_handler.connection_pool_list(:writing).map(&:inspect)}"
#   end

#   config.before(:rollback) do
#     puts "[BEFORE_ALL] connection pools before unpin_connection! #{::ActiveRecord::Base.connection_handler.connection_pool_list(:writing).map(&:inspect)}"
#   end
# end

describe "let_it_be vs lazy multi db" do
  let_it_be(:user) { TestProf::FactoryBot.create(:user) }

  # Loading an AR class with a custom DB configuration
  # triggers a new connection pool creation that hasn't been tracked by
  # before_all...
  let!(:dual_comments_class) do
    Class.new(ApplicationRecord) do
      def self.name
        "DualCommentsRecord"
      end

      self.abstract_class = true

      connects_to database: {writing: :comments, reading: :primary} if multi_db?
    end.then do |record_class|
      Class.new(record_class) do
        self.table_name = "comments"

        belongs_to :user, dependent: :destroy
      end
    end
  end

  specify do
    expect(User.count).to eq 2

    dual_comments_class.create!(user: user, comment: "Hello!")
  end

  specify do
    expect(TestProf::FactoryBot.create(:comment)).to be_present
    expect(Comment.count).to eq 1
  end

  context "with clean fixture", :with_clean_fixture do
    specify { expect(User.count).to eq 0 }
  end
end
