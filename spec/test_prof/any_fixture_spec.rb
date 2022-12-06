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

    context "with before_fixtures_reset callback" do
      it "runs callback" do
        subject.register(:user) { TestProf::FactoryBot.create(:user) }
        subject.before_fixtures_reset { Post.delete_all }
        TestProf::FactoryBot.create(:post)

        subject.reset
        expect(User.count).to eq 0
        expect(Post.count).to eq 0
      end
    end

    context "with after_fixtures_reset callback" do
      it "runs callback" do
        subject.register(:user) { TestProf::FactoryBot.create(:user) }
        subject.after_fixtures_reset { Post.delete_all }
        TestProf::FactoryBot.create(:post, user: nil)

        subject.reset
        expect(User.count).to eq 0
        expect(Post.count).to eq 0
      end
    end
  end

  describe "#register_dump" do
    before(:all) do
      Post.delete_all
      User.delete_all
    end

    after do
      subject.reset
      # Reset manually data populated via CLI tools
      Post.delete_all
      User.delete_all

      ENV.delete("ANYFIXTURE_FORCE_DUMP") if ENV.key?("ANYFIXTURE_FORCE_DUMP")

      described_class.remove_instance_variable(:@config)
    end

    it "saves and restores SQL dump" do
      # initialize sqlite sequence
      tmp_user = User.create!(name: "tmp")
      tmp_user.destroy!

      crypto = "crypto$5a$31$OsQLJ8tnIkCChMDcd?AiD?S.c/xUwe.Sk"
      how_are_you = "How are you doing?\nOK?"

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

          User.connection.execute "UPDATE users SET tag='ignore' WHERE id=#{User.connection.quote(jack.id)}; /*any_fixture:ignore*/"
        end
      end.to change(User, :count).by(2).and change(Post, :count).by(3)

      digest = TestProf::AnyFixture::Dump::Digest.call(__FILE__)
      dump_path = Pathname.new(
        File.join(TestProf.config.output_dir, "any_dumps", "users-#{digest}.sql")
      )

      expect(dump_path).to be_exist

      lucy_id = User.find_by(name: "Lucy").id

      expect(User.find_by(name: "Joe").tag).to eq "ignore"

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

      # Tag was ignored by dump
      expect(new_joe.tag).to be_nil
    end

    it "supports custom stale checks" do
      expect do
        subject.register_dump(
          "stale",
          after: ->(dump:, import:) { User.find_by!(name: "Jack").update!(tag: "dump-#{dump.digest}") unless import }
        ) do
          TestProf::FactoryBot.create(:user, name: "Jack")
          TestProf::FactoryBot.create(:user, name: "Lucy")
        end
      end.to change(User, :count).by(2)

      digest = TestProf::AnyFixture::Dump::Digest.call(__FILE__)
      dump_path = Pathname.new(
        File.join(TestProf.config.output_dir, "any_dumps", "stale-#{digest}.sql")
      )

      expect(dump_path).to be_exist

      subject.register_dump(
        "stale2",
        skip_if: ->(dump:) { User.where(name: "Jack", tag: "dump-#{dump.digest}").exists? }
      ) do
        TestProf::FactoryBot.create(:user, name: "Moe")
      end

      expect(User.count).to eq 2
    end

    it "supports custom cache keys" do
      expect do
        subject.register_dump(
          "cache_keys",
          cache_key: ["a", {b: :c}]
        ) do
          TestProf::FactoryBot.create(:user, name: "Jack")
          TestProf::FactoryBot.create(:user, name: "Lucy")
        end
      end.to change(User, :count).by(2)

      digest = TestProf::AnyFixture::Dump::Digest.call(__FILE__)
      cache_key = "#{digest}-a-b_c"
      dump_path = Pathname.new(
        File.join(TestProf.config.output_dir, "any_dumps", "cache_keys-#{cache_key}.sql")
      )

      expect(dump_path).to be_exist
      expect(User.count).to eq 2

      subject.reset

      expect(User.count).to eq 0
      expect(Post.count).to eq 0

      subject.register_dump(
        "cache_keys",
        cache_key: "a-b_c"
      ) { false }

      expect(User.count).to eq 2
    end

    it "provides success info" do
      expect do
        expect do
          subject.register_dump(
            "success",
            after: ->(dump:, import:) { User.find_by!(name: "Jack").update!(tag: "dump-#{dump.digest}") if dump.success? }
          ) do
            TestProf::FactoryBot.create(:user, name: "Jack")
            TestProf::FactoryBot.create(:user, name: nil)
          end
        end.to change(User, :count).by(1)
      end.to raise_error(ActiveRecord::RecordInvalid)

      expect(User.find_by(name: "Jack").tag).to be_nil
    end

    it "allow force recreation if ANYFIXTURE_DUMP_FORCE env var is provided" do
      expect do
        subject.register_dump("force-me") do
          TestProf::FactoryBot.create(:user, name: "Jack")
        end
      end.to change(User, :count).by(1)

      subject.reset
      described_class.remove_instance_variable(:@config)

      # Force only specific dump (unmatching)
      ENV["ANYFIXTURE_FORCE_DUMP"] = "stale"

      expect do
        subject.register_dump("force-me") { raise "Dump was called" }
      end.to change(User, :count).by(1)

      subject.reset
      described_class.remove_instance_variable(:@config)

      # Force only specific dump (matching)
      ENV["ANYFIXTURE_FORCE_DUMP"] = "force-m"

      expect do
        subject.register_dump("force-me") { raise "Dump was called" }
      end.to raise_error("Dump was called")

      subject.reset
      described_class.remove_instance_variable(:@config)

      # Force everything
      ENV["ANYFIXTURE_FORCE_DUMP"] = "1"

      expect do
        subject.register_dump("force-me") { raise "Dump was called" }
      end.to raise_error("Dump was called")
    end

    it "support non-cleanable dumps" do
      expect do
        subject.register_dump(
          "noclean",
          clean: false
        ) do
          TestProf::FactoryBot.create(:user, name: "Jack")
        end
      end.to change(User, :count).by(1)

      digest = TestProf::AnyFixture::Dump::Digest.call(__FILE__)
      dump_path = Pathname.new(
        File.join(TestProf.config.output_dir, "any_dumps", "noclean-#{digest}.sql")
      )

      expect(dump_path).to be_exist
      expect(User.count).to eq 1

      subject.reset

      expect(User.count).to eq 1
    end
  end
end
