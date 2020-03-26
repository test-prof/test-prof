# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require_relative "../../../support/ar_models"
require "test_prof/recipes/rspec/before_all"

module MyAdapter
  @nested_transaction_count = 0

  class << self
    def begin_transaction
      if @nested_transaction_count == 0
        execute "BEGIN"
      else
        execute "SAVEPOINT test_prof_#{@nested_transaction_count}"
      end
      @nested_transaction_count += 1
    end

    def rollback_transaction
      @nested_transaction_count -= 1
      if @nested_transaction_count == 0
        execute "ROLLBACK"
      else
        execute "ROLLBACK TO SAVEPOINT test_prof_#{@nested_transaction_count}"
      end
    end

    private

    def execute(sql)
      ActiveRecord::Base.connection.execute sql
    end
  end
end

TestProf::BeforeAll.adapter = MyAdapter

describe "User" do
  context "with before_all" do
    before_all do
      User.connection.execute(
        "insert into users (name) values ('Jack')"
      )
    end

    let(:user) { User.find_by!(name: "Jack") }

    it "validates name" do
      user.name = ""
      expect(user).not_to be_valid
    end

    it "clones" do
      cloned = user.clone
      expect(cloned.name).to include("Jack (cloned)")
    end
  end

  context "without before_all" do
    specify "no users" do
      expect(User.count).to eq 0
    end
  end
end
