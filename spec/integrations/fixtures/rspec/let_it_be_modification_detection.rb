# frozen_string_literal: true

require "test_prof/recipes/rspec/let_it_be"

# `order: defined` is to make sure the example that modifies the state
# is being run first, and the "victim" example runs afterwards.
RSpec.describe "Modification detection on associations", order: :defined do
  include TestProf::FactoryBot::Syntax::Methods

  # If you add `freeze: false` `let_it_be` option, state will leak
  # and the unsuspecting second example will fail.
  let_it_be(:user) { create(:user, name: "Original Name") }

  it "detects the leak" do
    expect { user.update!(name: "John Doe") }
      .to raise_error(FrozenError, /can't modify frozen Hash/)
  end

  it { expect(user.name).to eq("Original Name") }

  context "with an array of values" do
    let_it_be(:users) { create_list(:user, 2) }

    it "detects the leak" do
      expect { users.first.update!(name: "John Doe") }
        .to raise_error(FrozenError, /can't modify frozen Hash/)
    end
  end

  describe "infers `freeze: false`" do
    context "from `reload: true`" do
      let_it_be(:user, reload: true) { create(:user) }

      it "skips leakage detection" do
        expect { user.update(name: "Other Name") }
          .not_to raise_error
      end
    end

    context "from `refind: true`" do
      let_it_be(:user, refind: true) { create(:user) }

      it "skips leakage detection" do
        expect { user.update(name: "Other Name") }
          .not_to raise_error
      end
    end
  end
end
