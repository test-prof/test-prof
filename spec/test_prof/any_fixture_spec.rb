# frozen_string_literal: true

require "spec_helper"
require "test_prof/any_fixture"

describe TestProf::AnyFixture, :transactional do
  subject { described_class }

  after { described_class.reset }

  describe "#register" do
    it "invokes block only once for the same id" do
      block = double('block', call: 1)
      block2 = double('block2', call: 2)

      expect(block).to receive(:call)
      expect(block2).not_to receive(:call)

      expect(subject.register(:test) { block.call })
        .to eq 1

      expect(subject.register(:test) { block2.call })
        .to eq 1
    end
  end

  describe "#clean" do
    it "tracks AR queries and delete affected tables" do
      # add a record outside of any fixture to check
      # that we delete all records from the tables
      TestProf::FactoryBot.create(:user)

      expect do
        subject.register(:user) { TestProf::FactoryBot.create(:user) }
      end.to change(User, :count).by(1)

      expect do
        subject.register(:post) { TestProf::FactoryBot.create(:post) }
      end.to change(User, :count).by(1)
                                 .and change(Post, :count).by(1)

      subject.clean

      # Try to re-register user - should have no effect
      subject.register(:user) { TestProf::FactoryBot.create(:user) }

      expect(User.count).to eq 0
      expect(Post.count).to eq 0
    end
  end

  describe "#reset" do
    it "delete affected tables and reset cache" do
      expect do
        subject.register(:user) { TestProf::FactoryBot.create(:user) }
      end.to change(User, :count).by(1)

      subject.reset
      expect(User.count).to eq 0

      subject.register(:user) { TestProf::FactoryBot.create(:user) }

      expect(User.count).to eq 1
    end
  end
end
