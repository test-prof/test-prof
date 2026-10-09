# frozen_string_literal: true

require "action_controller/railtie"
require "action_view/railtie"
require "active_record/railtie"
require "rspec/rails"

require_relative "../../support/ar_models"

RSpec.configure do |config|
  config.use_transactional_fixtures = true
end

require "test_prof/recipes/rspec/before_all"

describe "before_all vs pool established in a non-writing role context" do
  before_all { TestProf::FactoryBot.create(:user) }

  specify do
    # A new writing pool is established (e.g., a model with `connects_to` is autoloaded)
    # while the current role is :reading. The "!connection.active_record" subscriber looks up
    # the pool using the current role and, thus, doesn't pin the new writing pool,
    # but it still shows up in the writing pools list on rollback.
    ActiveRecord::Base.connected_to(role: :reading) do
      Class.new(ActiveRecord::Base) do
        def self.name
          "NewPoolRecord"
        end

        self.abstract_class = true
        connects_to database: {writing: DB_CONFIG}
      end
    end

    expect(User.count).to eq 1
  end
end

describe "nested before_all vs pool established within nested context" do
  before_all { TestProf::FactoryBot.create(:user) }

  context "nested" do
    before_all { TestProf::FactoryBot.create(:user) }

    specify do
      # The new pool is pinned once (by the innermost before_all),
      # so it must be unpinned once, too (and not by every before_all level).
      Class.new(ActiveRecord::Base) do
        def self.name
          "NestedNewPoolRecord"
        end

        self.abstract_class = true
        establish_connection(DB_CONFIG)
      end

      expect(User.count).to eq 2
    end
  end
end
