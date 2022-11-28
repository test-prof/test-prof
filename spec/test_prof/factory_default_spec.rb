# frozen_string_literal: true

# Init FactoryDefault
require "test_prof/factory_default"

TestProf::FactoryDefault.init
TestProf::FactoryDefault.disable!

describe TestProf::FactoryDefault, :transactional do
  let(:preserve_traits) { false }
  let(:preserve_attributes) { false }

  before do
    described_class.enable!
    described_class.preserve_traits = preserve_traits
    described_class.preserve_attributes = preserve_attributes
  end

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
    let(:preserve_traits) { true }

    it "ignores default when trait is specified" do
      post = TestProf::FactoryBot.create_default(:post)
      post_traited = TestProf::FactoryBot.create(:post, :with_traited_user)

      expect(post.user).to eq user
      expect(post_traited.user).not_to eq user
    end

    context "when has default with the trait" do
      let!(:traited_user) { TestProf::FactoryBot.create_default(:user, :traited) }

      it "re-uses default record for this trait" do
        post = TestProf::FactoryBot.create_default(:post)
        post_traited = TestProf::FactoryBot.create(:post, :with_traited_user)

        expect(post.user).to eq user
        expect(post_traited.user).to eq traited_user
      end
    end
  end

  context "when preserve_attributes = true" do
    let(:preserve_attributes) { true }

    it "ignores default when explicit attributes don't match" do
      post = TestProf::FactoryBot.create(:post, :with_tagged_user)

      expect(post.user).not_to eq user
    end

    it "re-uses default when attributes match" do
      user.update!(tag: "some tag")

      post = TestProf::FactoryBot.create(:post, :with_tagged_user)

      expect(post.user).to eq user
    end
  end
end
