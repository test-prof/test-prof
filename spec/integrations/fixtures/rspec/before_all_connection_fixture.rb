# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require_relative "../../../support/ar_models"
require_relative "../../../support/transactional_context"
require "test_prof/recipes/rspec/before_all"

describe "database connection owner" do
  context "with before_all" do
    before_all {}

    it "uses the connection owned by main thread" do
      main_thread = Thread.current
      Thread.new do
        expect(ActiveRecord::Base.connection.owner).to eq(main_thread)
      end.join
    end
  end

  context "without before_all" do
    it "uses the connection owned by each thread" do
      Thread.new do
        child_thread = Thread.current
        expect(ActiveRecord::Base.connection.owner).to eq(child_thread)
      end.join
    end
  end
end
