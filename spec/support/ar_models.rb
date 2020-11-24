# frozen_string_literal: true

require "active_record"
require "fabrication"
require "test_prof"
require "test_prof/factory_bot"

require "activerecord-jdbc-adapter" if defined? JRUBY_VERSION
require "activerecord-jdbcsqlite3-adapter" if defined? JRUBY_VERSION

DB_CONFIG =
  if ENV["DB"] == "sqlite-file"
    FileUtils.mkdir_p TestProf.config.output_dir
    {adapter: "sqlite3", database: File.join(TestProf.config.output_dir, "testdb.sqlite")}
  elsif ENV["DB"] == "postgres"
    require "active_record/database_configurations"
    config = ActiveRecord::DatabaseConfigurations::UrlConfig.new(
      "test",
      "primary",
      ENV.fetch("DATABASE_URL"),
      {"database" => ENV.fetch("DB_NAME", "test_prof_test")}
    )
    config.config
  else
    {adapter: "sqlite3", database: ":memory:"}
  end

ActiveRecord::Base.establish_connection(**DB_CONFIG)

ActiveRecord::Base.connection.truncate_tables(*ActiveRecord::Base.connection.tables)

ActiveRecord::Schema.define do
  using_pg = ActiveRecord::Base.connection.adapter_name == "PostgreSQL"

  enable_extension "pgcrypto" if using_pg

  create_table :users, id: (using_pg ? :uuid : :bigint), if_not_exists: true do |t|
    t.string :name
    t.string :tag
  end

  create_table :posts, if_not_exists: true do |t|
    t.text :text
    if using_pg
      t.uuid :user_id
    else
      t.bigint :user_id
    end
    t.foreign_key :users if ActiveRecord::VERSION::MAJOR >= 4
    t.timestamps
  end
end

ActiveRecord::Base.logger = Logger.new(STDOUT) if ENV["LOG"]

class User < ActiveRecord::Base
  validates :name, presence: true
  has_many :posts, dependent: :destroy

  def clone
    copy = dup
    copy.name = "#{name} (cloned)"
    copy
  end
end

class Post < ActiveRecord::Base
  belongs_to :user

  attr_accessor :dirty
end

TestProf::FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "John #{n}" }

    trait :with_posts do
      after(:create) do
        TestProf::FactoryBot.create_pair(:post)
      end
    end

    trait :traited do
      tag { "traited" }
    end

    trait :other_trait do
      tag { "other_trait" }
    end
  end

  factory :post do
    sequence(:text) { |n| "Post ##{n}" }
    user

    trait :with_bad_user do
      user { create(:user) }
    end

    trait :with_traited_user do
      association :user, factory: %i[user traited]
    end

    trait :with_other_traited_user do
      association :user, factory: %i[user other_trait]
    end
  end
end

Fabricator(:user) do
  name Fabricate.sequence(:name) { |n| "John #{n}" }
end

Fabricator(:post) do
  text Fabricate.sequence(:text) { |n| "Post ##{n}}" }
  user
end
