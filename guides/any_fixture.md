# Any Fixture

Fixtures are the great way to increase your test suite performance, but for the large project, they are very hard to maintain.

We propose a more general approach to lazy-generate the _global_ state for your test suite – AnyFixture.

With AnyFixture you can use any block of code for data generation, and it will take care of cleaning it out at the end of the run.

Consider an example:

```ruby
# The best way to use AnyFixture is through RSpec shared contexts
RSpec.shared_context "account", account: true do
  # You should call AnyFixture outside of transaction to re-use the same
  # data between examples
  before(:all) do
    # The provided name ("account") should be unique.
    @account = TestProf::AnyFixture.register(:account) do
      # Do anything here, AnyFixture keeps track of affected DB tables
      # For example, you can use factories here
      create(:account)

      # or with Fabrication
      Fabricate(:account)

      # or with plain old AR
      Account.create!(name: 'test')
    end
  end

  let(:account) { @account }

  # Or hard-reload object if there is chance of in-place modification within tests
  let(:account) { Account.find(@account.id) }
end


# Then in your tests

# Active this fixture using a tag
describe UsersController, :account do
  ...
end

# This test also uses the same account record,
# no double-creation
describe PostsController, :account do
  ...
end
```

## Instructions

In your `spec_helper.rb`:

```ruby
require "test_prof/recipes/rspec/any_fixture"
```

Now you can use `TestProf::AnyFixture` in your tests.
