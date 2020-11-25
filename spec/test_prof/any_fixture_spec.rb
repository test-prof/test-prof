# frozen_string_literal: true

require "test_prof/any_fixture"

describe TestProf::AnyFixture, :transactional, :postgres, sqlite: :file do
  subject { described_class }

  after { described_class.reset }

  describe "#register" do
    it "invokes block only once for the same id" do
      block = double("block", call: 1)
      block2 = double("block2", call: 2)

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

  describe "#register_dump" do
    after { subject.reset }

    it "saves and restores SQL dump" do
      # initialize sqlite sequence
      tmp_user = User.create!(name: "tmp")
      tmp_user.destroy!

      crypto = "crypto$5a$31$OsQLJ8tnIkCChMDcd?AiD?S.c/xUwe.Sk"
      how_are_you = "How are you doing? OK?"

      expect do
        subject.register_dump("users") do
          jack = TestProf::FactoryBot.create(:user, name: "Jack")
          TestProf::FactoryBot.create(:user, name: "Lucy").tap do |user|
            TestProf::FactoryBot.create(:post, user: user, text: crypto)
            TestProf::FactoryBot.create(:post, user: user).tap do |post|
              post.update!(user: jack, text: how_are_you)
            end
          end

          if defined?(ActiveRecord::Import)
            Post.import([Post.new(text: crypto, user: jack)], validate: false)
          else
            Post.insert_all([{text: crypto, user_id: jack.id, created_at: Time.now, updated_at: Time.now}])
          end

          jack.update!(name: "Joe")
          TestProf::FactoryBot.create(:user, name: "Deadman").tap(&:destroy!)
        end
      end.to change(User, :count).by(2).and change(Post, :count).by(3)

      digest = TestProf::AnyFixture::Dump::Digest.call(__FILE__)
      dump_path = Pathname.new(
        File.join(TestProf.config.output_dir, "any_dumps", "users-#{digest}.sql")
      )

      expect(dump_path).to be_exist

      lucy_id = User.find_by(name: "Lucy").id

      subject.reset

      expect(User.count).to eq 0
      expect(Post.count).to eq 0

      subject.register_dump("users") { false }

      expect(User.count).to eq 2
      expect(Post.count).to eq 3

      new_lucy = User.find_by!(name: "Lucy")
      new_joe = User.find_by!(name: "Joe")

      expect(new_lucy.id).to eq lucy_id
      expect(new_lucy.posts.size).to eq 1
      expect(new_joe.posts.size).to eq 2

      expect(Post.find_by(text: crypto).user).to eq new_lucy
      expect(Post.find_by(text: how_are_you).user).to eq new_joe
    end
  end
end
