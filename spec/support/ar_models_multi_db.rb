# frozen_string_literal: true

require "active_record"
require "fabrication"
require "test_prof"
require "test_prof/factory_bot"

require "activerecord-jdbc-adapter" if defined? JRUBY_VERSION
require "activerecord-jdbcsqlite3-adapter" if defined? JRUBY_VERSION

begin
  require "activerecord-import"
rescue LoadError
end

DB_CONFIG = begin
  pp TestProf.config.output_dir
  FileUtils.mkdir_p TestProf.config.output_dir
  db_blog_path = File.join(TestProf.config.output_dir, "test_blog.sqlite")
  FileUtils.rm(db_blog_path) if File.file?(db_blog_path)
  db_accounts_path = File.join(TestProf.config.output_dir, "test_account.sqlite")
  FileUtils.rm(db_accounts_path) if File.file?(db_accounts_path)
  { blog: 
      {adapter: "sqlite3", database: db_blog_path},
    account: 
      {adapter: "sqlite3", database: db_accounts_path} 
  }
end

ActiveRecord::Base.configurations = DB_CONFIG

ActiveRecord::Base.establish_connection(**DB_CONFIG[:blog])
ActiveRecord::Schema.define do
  create_table :posts, if_not_exists: true do |t|
    t.text :text
    t.bigint :user_id
    t.timestamps
  end
end

ActiveRecord::Base.establish_connection(**DB_CONFIG[:account])
ActiveRecord::Schema.define do
  create_table :users, if_not_exists: true do |t|
    t.string :name
    t.string :tag
  end
end

ActiveRecord::Base.logger =
  if ENV["DEBUG"]
    Logger.new($stdout)
  else
    Logger.new(IO::NULL)
  end

class AccountRecord < ActiveRecord::Base
  self.abstract_class = true

  connects_to database: { writing: :account, readon: :account }
end

class BlogRecord < ActiveRecord::Base
  self.abstract_class = true

  connects_to database: { writing: :blog, readon: :blog }
end

Object.send(:remove_const, :User) if defined? User
class User < AccountRecord
  validates :name, presence: true

  def clone
    copy = dup
    copy.name = "#{name} (cloned)"
    copy
  end
end

Object.send(:remove_const, :Post) if defined? Post
class Post < BlogRecord
  attr_accessor :dirty
end

TestProf::FactoryBot.factories.clear

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

Fabricator(:user_multi_db) do
  name { sequence(:name) { |n| "John #{n}" } }
end

Fabricator(:post_multi_db) do
  text { sequence(:text) { |n| "Post ##{n}}" } }
  user
end
