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

### Minitest (Experimental)

\*_Experimental_ means that I haven't tried it in _production_.

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

> @since v0.9.0

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

You just need to make sure that you require `isolator` after TestProf helpers or require the patch explicitly:

```ruby
# after loading before_all or/and let_it_be
require "test_prof/before_all/isolator"
```
