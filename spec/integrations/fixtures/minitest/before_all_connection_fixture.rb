# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require_relative "../../../support/ar_models"
require_relative "../../../support/transactional_minitest"
require "minitest/autorun"

require "test_prof/recipes/minitest/before_all"

describe "database connection owner" do
  describe "with before_all" do
    include TestProf::BeforeAll::Minitest
    before_all {}

    it "uses the connection owned by main thread" do
      main_thread = Thread.current
      Thread.new do
        assert_equal ActiveRecord::Base.connection.owner, main_thread
      end.join
    end
  end

  describe "without before_all" do
    it "uses the connection owned by each thread" do
      Thread.new do
        child_thread = Thread.current
        assert_equal ActiveRecord::Base.connection.owner, child_thread
      end.join
    end
  end
end
