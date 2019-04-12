# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require_relative "../../../support/ar_models"
require "test_prof/recipes/rspec/before_all"

module MyAdapter
  class << self
    def begin_transaction
      ActiveRecord::Base.connection.execute "BEGIN"
    end

    def rollback_transaction
      ActiveRecord::Base.connection.execute "ROLLBACK"
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
