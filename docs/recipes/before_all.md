# Before All

Rails has a great feature – `transactional_tests`, i.e. running each example within a transaction which is roll-backed in the end.

Thus no example pollutes global database state.

But what if have a lot of examples with a common setup?

Of course, we can do something like this:

```ruby
describe BeatleWeightedSearchQuery do
  before(:each) do
    @paul = create(:beatle, name: "Paul")
    @ringo = create(:beatle, name: "Ringo")
    @george = create(:beatle, name: "George")
    @john = create(:beatle, name: "John")
  end

  # and about 15 examples here
end
```

Or you can try `before(:all)`:

```ruby
describe BeatleWeightedSearchQuery do
  before(:all) do
    @paul = create(:beatle, name: "Paul")
    # ...
  end

  # ...
end
```

But then you have to deal with database cleaning, which can be either tricky or slow.

There is a better option: we can wrap the whole example group into a transaction.
And that's how `before_all` works:

```ruby
describe BeatleWeightedSearchQuery do
  before_all do
    @paul = create(:beatle, name: "Paul")
    # ...
  end

  # ...
end
```

That's all!

**NOTE**: requires RSpec >= 3.3.0.

**NOTE**: Great superpower that `before_all` provides comes with a great responsibility.
Make sure to check the [Caveats section](#caveats) of this document for details.

## Instructions

### Multiple database support

The ActiveRecord BeforeAll adapter will only start a transaction using ActiveRecord::Base connection.
If you want to ensure `before_all` can use multiple connections, you need to ensure the connection
classes are loaded before using `before_all`.

For example, imagine you have `ApplicationRecord` and a separate database for user accounts:

```ruby
class Users < AccountsRecord
  # ...
end

class Articles < ApplicationRecord
  # ...
end
```

Then those two Connection Classes do need to be loaded before the tests are run:

```ruby

# Ensure connection classes are loaded
ApplicationRecord
AccountsRecord
```

This code can be added to `rails_helper.rb` or the rake tasks that runs minitests.

### RSpec

In your `rails_helper.rb` (or `spec_helper.rb` after *ActiveRecord* has been loaded):

```ruby
require "test_prof/recipes/rspec/before_all"
```

**NOTE**: `before_all` (and `let_it_be` that depends on it), does not wrap individual
tests in a database transaction of its own. Use Rails' native `use_transactional_tests`
(`use_transactional_fixtures` in Rails < 5.1), RSpec Rails' `use_transactional_fixtures`,
DatabaseCleaner, or custom code that begins a transaction before each test and rolls it
back after.

### Minitest

It is possible to use `before_all` with Minitest too:

```ruby
require "test_prof/recipes/minitest/before_all"

class MyBeatlesTest < Minitest::Test
  include TestProf::BeforeAll::Minitest

  before_all do
    @paul = create(:beatle, name: "Paul")
    @ringo = create(:beatle, name: "Ringo")
    @george = create(:beatle, name: "George")
    @john = create(:beatle, name: "John")
  end

  # define tests which could access the object defined within `before_all`
end
```

In addition to `before_all`, TestProf also provides a `after_all` callback, which is called right before the transaction open by `before_all` is closed, i.e., after the last example from the test class completes.

## Database adapters

You can use `before_all` not only with ActiveRecord (which is supported out-of-the-box) but with other database tools too.

All you need is to build a custom adapter and configure `before_all` to use it:

```ruby
class MyDBAdapter
  # before_all adapters must implement two methods:
  # - begin_transaction
  # - rollback_transaction
  def begin_transaction
    # ...
  end

  def rollback_transaction
    # ...
  end
end

# And then set adapter for `BeforeAll` module
TestProf::BeforeAll.adapter = MyDBAdapter.new
```

## Hooks

You can register callbacks to run before/after `before_all` opens and rollbacks a transaction:

```ruby
TestProf::BeforeAll.configure do |config|
  config.before(:begin) do
    # do something before transaction opens
  end
  # after(:begin) is also available

  config.after(:rollback) do
    # do something after transaction closes
  end
  # before(:rollback) is also available
end
```

See the example in [Discourse](https://github.com/discourse/discourse/blob/4a1755b78092d198680c2fe8f402f236f476e132/spec/rails_helper.rb#L81-L141).

## Caveats

### Database is rolled back to a pristine state, but the objects are not

If you modify objects generated within a `before_all` block in your examples, you maybe have to re-initiate them:

```ruby
before_all do
  @user = create(:user)
end

let(:user) { @user }

it "when user is admin" do
  # we modified our object in-place!
  user.update!(role: 1)
  expect(user).to be_admin
end

it "when user is regular" do
  # now @user's state depends on the order of specs!
  expect(user).not_to be_admin
end
```

The easiest way to solve this is to reload record for every example (it's still much faster than creating a new one):

```ruby
before_all do
  @user = create(:user)
end

# Note, that @user.reload may not be enough,
# 'cause it doesn't reset associations
let(:user) { User.find(@user.id) }

# or with Minitest
def setup
  @user = User.find(@user.id)
end
```

### Database is not rolled back between tests

Database is not rolled back between RSpec examples, only between example groups.
We don't want to reinvent the wheel and encourage you to use other tools that
provide this out of the box.

If you're using RSpec Rails, turn on `RSpec.configuration.use_transactional_fixtures` in your `spec/rails_helper.rb`:

```ruby
RSpec.configure do |config|
  config.use_transactional_fixtures = true # RSpec takes care to use `use_transactional_tests` or `use_transactional_fixtures` depending on the Rails version used
end
```

Make sure to set `use_transactional_tests` (`use_transactional_fixtures` in Rails < 5.1) to `true` if you're using Minitest.

If you're using DatabaseCleaner, make sure it rolls back the database between tests.

## Usage with Isolator

[Isolator](https://github.com/palkan/isolator) is a runtime detector of potential atomicity breaches within DB transactions (e.g. making HTTP calls or enqueuing background jobs).

TestProf recognizes Isolator out-of-the-box and make it ignore `before_all` transactions.

You just need to make sure that you require `isolator` before loading `before_all` (or `let_it_be`).

Alternatively, you can load the patch explicitly:

```ruby
# after loading before_all or/and let_it_be
require "test_prof/before_all/isolator"
```

## Using Rails fixtures (_experimental_)

If you want to use fixtures within a `before_all` hook, you must explicitly opt-in via `setup_fixture:` option:

```ruby
before_all(setup_fixtures: true) do
  @user = users(:john)
  @post = create(:post, user: user)
end
```

Works for both Minitest and RSpec.

You can also enable fixtures globally (i.e., for all `before_all` hooks):

```ruby
TestProf::BeforeAll.configure do |config|
  config.setup_fixtures = true
end
```

## Global Tags

You can register callbacks for specific RSpec Example Groups using tags:

```ruby
TestProf::BeforeAll.configure do |config|
  config.before(:begin, reset_sequences: true, foo: :bar) do
    warn <<~MESSAGE
      Do NOT create objects outside of transaction
      because all db sequences will be reset to 1
      in every single example, so that IDs of new objects
      can get into conflict with the long-living ones.
    MESSAGE
  end
end
```
