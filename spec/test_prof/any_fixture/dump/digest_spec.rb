# frozen_string_literal: true

require "test_prof/any_fixture"

describe TestProf::AnyFixture::Dump::Digest do
  subject { described_class }

  before(:all) do
    FileUtils.mkdir_p("tmp/any_fixture_digest")
    File.write("tmp/any_fixture_digest/1.txt", "Boo!")
  end

  after(:all) do
    FileUtils.rm_rf("tmp/any_fixture_digest")
  end

  around do |ex|
    was_paths = TestProf::AnyFixture.config.default_dump_watch_paths
    ex.run
    TestProf::AnyFixture.config.default_dump_watch_paths.tap do |paths|
      paths.clear
      was_paths.each { |path| paths << path }
    end
  end

  it "returns nil if not paths specified" do
    TestProf::AnyFixture.config.default_dump_watch_paths.clear

    expect(described_class.call).to be_nil
  end

  it "uses globally configured paths" do
    digest = subject.call

    TestProf::AnyFixture.config.default_dump_watch_paths << __FILE__

    expect(subject.call).not_to eq digest
  end

  it "accepts file paths" do
    digest = subject.call("tmp/any_fixture_digest/1.txt")

    File.write("tmp/any_fixture_digest/1.txt", "Boo!2")

    expect(subject.call("tmp/any_fixture_digest/1.txt")).not_to eq digest
  end

  it "accepts globs" do
    digest = subject.call("tmp/any_fixture_digest/*.txt")

    File.write("tmp/any_fixture_digest/2.txt", "Moooo!")

    expect(subject.call("tmp/any_fixture_digest/*.txt")).not_to eq digest
  end

  it "does not change if files contents stays the same" do
    digest = subject.call("tmp/any_fixture_digest/1.txt")

    File.write("tmp/any_fixture_digest/1.txt", "Boo! 2")

    digest2 = subject.call("tmp/any_fixture_digest/1.txt")

    File.write("tmp/any_fixture_digest/1.txt", "Boo!")

    digest3 = subject.call("tmp/any_fixture_digest/1.txt")

    expect(digest).to eq digest3
    expect(digest2).not_to eq digest
  end
end
