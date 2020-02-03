# frozen_string_literal: true

require "test_prof/recipes/active_record_one_love"

describe TestProf::ActiveRecordSharedConnection, :transactional do
  subject { described_class }

  before(:all) { described_class.enable! }
  after(:all) { described_class.disable! }

  after { described_class.instance_variable_set(:@ignores, nil) }

  it "forces AR to use the same connection for all threads" do
    conn = ActiveRecord::Base.connection

    thread_conn = nil

    Thread.new { thread_conn = ActiveRecord::Base.connection }.join

    expect(thread_conn).to eq conn
  end

  context "when disabled" do
    before { described_class.disable! }
    after { described_class.enable! }

    it "uses connection per thread" do
      conn = ActiveRecord::Base.connection

      thread_conn = nil

      Thread.new { thread_conn = ActiveRecord::Base.connection }.join

      expect(thread_conn).not_to eq conn
    end
  end

  context "when ignored" do
    before { described_class.ignore { |config| config[:adapter] == "sqlite3" } }

    it "uses connection per thread" do
      conn = ActiveRecord::Base.connection

      thread_conn = nil

      Thread.new { thread_conn = ActiveRecord::Base.connection }.join

      expect(thread_conn).not_to eq conn
    end
  end
end
