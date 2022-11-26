# frozen_string_literal: true

# Init FactoryDefault
require "test_prof/factory_default"

TestProf::FactoryDefault.init
TestProf::FactoryDefault.disable!

describe TestProf::FactoryDefault, :transactional do
  before { described_class.enable! }
  after do
    described_class.reset
    described_class.disable!
  end

  let!(:user) { TestProf::FactoryBot.create_default(:user) }

  it "re-uses the same default record" do
    post = TestProf::FactoryBot.create(:post)

    expect(post.user).to eq user
  end

  it "re-uses default record independently of traits" do
    post = TestProf::FactoryBot.create(:post, :with_traited_user)

    expect(post.user).to eq user
  end

  it "re-uses default record independently of attributes" do
    post = TestProf::FactoryBot.create(:post, :with_tagged_user)

    expect(post.user).to eq user
  end

  specify ".disable!(&block)" do
    post = TestProf::FactoryBot.skip_factory_default { TestProf::FactoryBot.create(:post) }
    expect(post.user).not_to eq(user)
  end

  context "when preserve_traits = true" do
    before { described_class.preserve_traits = true }
    after { described_class.preserve_traits = false }

    it "ignores default when trait is specified" do
      post = TestProf::FactoryBot.create_default(:post)
      post_traited = TestProf::FactoryBot.create(:post, :with_traited_user)

      expect(post.user).to eq user
      expect(post_traited.user).not_to eq user
    end
  end

  xcontext "when preserve_attributes = true" do
    before { described_class.preserve_attributes = true }
    after { described_class.preserve_attributes = false }

    it "ignores default when explicit attributes don't match" do
      post = TestProf::FactoryBot.create_default(:post)
      user_2 = TestProf::FactoryBot.create(:user, tag: "another")
      post_2 = TestProf::FactoryBot.create(:post, user: user_2)

      expect(post.user).to eq user
      expect(post_2.user).to eq user_2
      expect(post_2).not_to eq post
    end

    it "re-uses default when attributes match" do
      post = TestProf::FactoryBot.create_default(:post, text: "Test")
      post_2 = TestProf::FactoryBot.create(:post, text: "Test")

      expect(post_2).to eq post
    end
  end
end
