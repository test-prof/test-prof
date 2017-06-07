# frozen_string_literal: true

require "active_record"
require "factory_girl"

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')

ActiveRecord::Schema.define do
  create_table :users do |t|
    t.string :name
  end
end

class User < ActiveRecord::Base
  validates :name, presence: true

  def clone
    copy = dup
    copy.name = "#{name} (cloned)"
    copy
  end
end

FactoryGirl.define do
  factory :user do
    name { |n| "John #{n}" }
  end
end
