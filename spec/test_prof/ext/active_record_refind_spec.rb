# frozen_string_literal: true

require "test_prof/ext/active_record_refind"

using TestProf::Ext::ActiveRecordRefind

describe TestProf::Ext::ActiveRecordRefind, :transactional do
  describe "#refind" do
    it "works" do
      user = TestProf::FactoryBot.create(:user)
      TestProf::FactoryBot.create(:post, user: user, text: "clean")
      user.posts.first.text = "dirty"

      ruser = user.refind

      expect(ruser).to eq user
      expect(ruser).not_to be_equal user
      expect(ruser.posts.first.text).to eq "clean"
    end

    it "ignores default scopes" do
      scoped_post_class = Class.new(Post) do
        default_scope { where.not(text: "dirty") }
      end

      post = scoped_post_class.create!(text: "dirty")

      rpost = post.refind

      expect(rpost.text).to eq "dirty"
    end
  end
end
