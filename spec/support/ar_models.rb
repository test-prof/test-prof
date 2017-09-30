# frozen_string_literal: true

require "active_record"
require "factory_girl"
require "fabrication"

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')

ActiveRecord::Schema.define do
  create_table :users do |t|
    t.string :name
  end

  create_table :posts do |t|
    t.text :text
    t.integer :user_id
    t.foreign_key :users
  end
end

ActiveRecord::Base.logger = Logger.new(STDOUT) if ENV['LOG']

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
end

FactoryGirl.define do
  factory :user do
    sequence(:name) { |n| "John #{n}" }

    trait :with_posts do
      after(:create) do
        FactoryGirl.create_pair(:post)
      end
    end
  end

  factory :post do
    sequence(:text) { |n| "Post ##{n}}" }
    user
  end
end

Fabricator(:user) do
  name Fabricate.sequence(:name) { |n| "John #{n}" }
end

Fabricator(:post) do
  text Fabricate.sequence(:text) { |n| "Post ##{n}}" }
  user
end
