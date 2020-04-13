# frozen_string_literal: true

require_relative "../../../support/ar_models"
require_relative "../../../support/transactional_context"

require "test_prof/recipes/rspec/let_it_be"

RSpec.describe "Modification detection", let_it_be_frost: true do
  include TestProf::FactoryBot::Syntax::Methods

  # `order: defined` is to make sure the example that modifies the state
  # is being run first, and the "victim" example runs afterwards.

  describe "first order state leakage", order: :defined do
    # If you add `freeze: false` `let_it_be` option, state will leak
    # and the unsuspecting second example will fail.
    let_it_be(:user) { create(:user, name: "Original Name") }

    it "detects the leak" do
      expect { user.update!(name: "John Doe") }
        .to raise_error(/can't modify frozen/)
    end

    it { expect(user.name).to eq("Original Name") }
  end

  describe "second order state leakage", order: :defined do
    let_it_be(:post) { create(:post, user: create(:user, name: "Original Name")) }

    it "detects the leak" do
      expect { post.user.update!(name: "John Doe") }
        .to raise_error(/can't modify frozen/)
    end

    it { expect(post.user.name).to eq("Original Name") }
  end

  describe "no state leakage with transactional tests with `refind: true`", :transactional, order: :defined do
    let_it_be(:post, refind: true) { create(:post, user: create(:user, name: "Original Name")) }

    it "leaks" do
      post.user.update!(name: "John Doe")
    end

    it { expect(post.user.name).to eq("Original Name") }
  end

  describe "no state leakage with transactional tests with `reload: true`", :transactional, order: :defined do
    let_it_be(:post, reload: true) { create(:post, user: create(:user, name: "Original Name")) }

    it "leaks" do
      post.user.update!(name: "John Doe")
    end

    it { expect(post.user.name).to eq("Original Name") }
  end

  context "with an array of values" do
    let_it_be(:users) { create_list(:user, 2) }

    it "detects the leak in an array item" do
      expect { users.first.update!(name: "John Doe") }
        .to raise_error(/can't modify frozen/)
    end

    it "detects the leak in the array itself" do
      expect { users << "yet another user" }
        .to raise_error(/can't modify frozen/)
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

    context "from metadata", let_it_be_frost: false do
      let_it_be(:user) { create(:user) }
      let_it_be(:users) { [user] }

      it "skips leakage detection" do
        expect { user.update!(name: "Other Name") }
          .not_to raise_error
      end
    end
  end

  describe "combination of cross-referenced freezable and non-freezable objects" do
    describe "level one" do
      let_it_be(:one, freeze: false) { ["one"] }

      describe "level two" do
        let_it_be(:two) { [one, ["two"]] }

        describe "level three" do
          let_it_be(:three, freeze: false) { [one, two, "three"] }

          it "only freezes what's necessary" do
            expect { one.push(1) }.not_to raise_error
            expect { two.push(2) }.to raise_error(/can't modify frozen/)
            expect { two.first.push(2) }.not_to raise_error
            expect { two.last.push(2) }.to raise_error(/can't modify frozen/)
            expect { three.push(3) }.not_to raise_error
          end
        end
      end
    end
  end
end
