# frozen_string_literal: true

require "test_prof/recipes/rspec/let_it_be"

RSpec.describe "Modification detection" do
  include TestProf::FactoryBot::Syntax::Methods

  # `order: defined` is to make sure the example that modifies the state
  # is being run first, and the "victim" example runs afterwards.

  describe "first order state leakage", order: :defined do
    # If you add `freeze: false` `let_it_be` option, state will leak
    # and the unsuspecting second example will fail.
    let_it_be(:user) { create(:user, name: "Original Name") }

    it "detects the leak" do
      expect { user.update!(name: "John Doe") }
        .to raise_error(FrozenError, /can't modify frozen/)
    end

    it { expect(user.name).to eq("Original Name") }
  end

  describe "second order state leakage", order: :defined do
    let_it_be(:post) { create(:post, user: create(:user, name: "Original Name")) }

    it "detects the leak" do
      expect { post.user.update!(name: "John Doe") }
        .to raise_error(FrozenError, /can't modify frozen/)
    end

    it { expect(post.user.name).to eq("Original Name") }
  end

  context "with an array of values" do
    let_it_be(:users) { create_list(:user, 2) }

    it "detects the leak in an array item" do
      expect { users.first.update!(name: "John Doe") }
        .to raise_error(FrozenError, /can't modify frozen/)
    end

    it "detects the leak in the array itself" do
      expect { users << "yet another user" }
        .to raise_error(FrozenError, /can't modify frozen/)
    end
  end

  describe "infers `freeze: false`" do
    context "from `reload: true`" do
      let_it_be(:user, reload: true) { create(:user) }
      let_it_be(:users) { [user] }

      it "skips leakage detection" do
        expect { user.update!(name: "Other Name") }
          .not_to raise_error
      end
    end

    context "from `refind: true`" do
      let_it_be(:user, refind: true) { create(:user) }
      let_it_be(:users) { [user] }

      it "skips leakage detection" do
        expect { user.update!(name: "Other Name") }
          .not_to raise_error
      end
    end

    context "from `freeze: false`" do
      let_it_be(:user, freeze: false) { create(:user) }
      let_it_be(:users) { [user] }

      it "skips leakage detection" do
        expect { user.update!(name: "Other Name") }
          .not_to raise_error
      end
    end

    context "from metadata", let_it_be_defrost: true do
      let_it_be(:user) { create(:user) }
      let_it_be(:users) { [user] }

      it "skips leakage detection" do
        expect { user.update!(name: "Other Name") }
          .not_to raise_error
      end
    end
  end

  describe "combination of cross-referenced reloaded and frozen objects" do
    # TODO: make sure stoplist works - smoke test, no specific expectation, just that there's no FrozenError
    # TODO: make sure stoplist is reset
    # TODO: make sure stoplist is not reset on each example/group, just the outermost one
  end
end
