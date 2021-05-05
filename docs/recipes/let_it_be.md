# Let It Be

Let's bring a little bit of magic and introduce a new way to set up a _shared_ test data.

Suppose you have the following setup:

```ruby
describe BeatleWeightedSearchQuery do
  let!(:paul) { create(:beatle, name: "Paul") }
  let!(:ringo) { create(:beatle, name: "Ringo") }
  let!(:george) { create(:beatle, name: "George") }
  let!(:john) { create(:beatle, name: "John") }

  specify { expect(subject.call("john")).to contain_exactly(john) }

  # and more examples here
end
```

We don't need to re-create the Fab Four for every example, do we?

We already have [`before_all`](./before_all.md) to solve the problem of _repeatable_ data:

```ruby
describe BeatleWeightedSearchQuery do
  before_all do
    @paul = create(:beatle, name: "Paul")
    # ...
  end

  specify { expect(subject.call("joh")).to contain_exactly(@john) }

  # ...
end
```

That technique works pretty good but requires us to use instance variables and define everything at once. Thus it's not easy to refactor existing tests which use `let/let!` instead.

With `let_it_be` you can do the following:

```ruby
describe BeatleWeightedSearchQuery do
  let_it_be(:paul) { create(:beatle, name: "Paul") }
  let_it_be(:ringo) { create(:beatle, name: "Ringo") }
  let_it_be(:george) { create(:beatle, name: "George") }
  let_it_be(:john) { create(:beatle, name: "John") }

  specify { expect(subject.call("john")).to contain_exactly(john) }

  # and more examples here
end
```

That's it! Just replace `let!` with `let_it_be`. That's equal to the `before_all` approach but requires less refactoring.

**NOTE**: Great superpower that `before_all` provides comes with a great responsibility.
Make sure to check the [Caveats section](#caveats) of this document for details.

## Instructions

In your `rails_helper.rb` or `spec_helper.rb`:

```ruby
require "test_prof/recipes/rspec/let_it_be"
```

In your tests:

```ruby
describe MySuperDryService do
  let_it_be(:user) { create(:user) }

  # ...
end
```

`let_it_be` won't automatically bring the database to its previous state between
the examples, it only does that between example groups.
Use Rails' native `use_transactional_tests` (`use_transactional_fixtures` in Rails < 5.1),
RSpec Rails' `use_transactional_fixtures`, DatabaseCleaner, or custom code that
begins a transaction before each test and rolls it back after.

## Caveats

### Database is rolled back to a pristine state, but the objects are not

If you modify objects generated within a `let_it_be` block in your examples, you maybe have to re-initiate them.
We have a built-in _modifiers_ support for that.

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

## Aliases

Naming is hard. Handling edge cases (the ones described above) is also tricky.

To solve this we provide a way to define `let_it_be` aliases with the predefined options:

```ruby
# rails_helper.rb
TestProf::LetItBe.configure do |config|
  # define an alias with `refind: true` by default
  config.alias_to :let_it_be_with_refind, refind: true
end

# then use it in your tests
describe "smth" do
  let_it_be_with_refind(:foo) { Foo.create }

  # refind can still be overridden
  let_it_be_with_refind(:bar, refind: false) { Bar.create }
end
```

## Modifiers

If you modify objects generated within a `let_it_be` block in your examples, you maybe have to re-initiate them to avoid state leakage between the examples.
Keep in mind that even though the database is rolled back to its pristine state, models themselves are not.

We have a built-in _modifiers_ support for getting models to their pristine state:

```ruby
# Use reload: true option to reload user object (assuming it's an instance of ActiveRecord)
# for every example
let_it_be(:user, reload: true) { create(:user) }

# it is almost equal to
before_all { @user = create(:user) }
let(:user) { @user.reload }

# You can also specify refind: true option to hard-reload the record
let_it_be(:user, refind: true) { create(:user) }

# it is almost equal to
before_all { @user = create(:user) }
let(:user) { User.find(@user.id) }
```

**NOTE:** make sure that you require `let_it_be` after `active_record` is loaded (e.g., in `rails_helper.rb` **after** requiring the Rails app); otherwise the `refind` and `reload` modifiers are not activated.

You can also use modifiers with array values, e.g. `create_list`:

```ruby
let_it_be(:posts, reload: true) { create_list(:post, 3) }

# it's the same as
before_all { @posts = create_list(:post, 3) }
let(:posts) { @posts.map(&:reload) }
```

### Custom Modifiers

If `reload` and `refind` is not enough, you can add your custom modifier:

```ruby
# rails_helper.rb
TestProf::LetItBe.configure do |config|
  # Define a block which will be called when you access a record first within an example.
  # The first argument is the pre-initialized record,
  # the second is the value of the modifier.
  #
  # This is how `reload` modifier is defined
  config.register_modifier :reload do |record, val|
    # ignore when `reload: false`
    next record unless val
    # ignore non-ActiveRecord objects
    next record unless record.is_a?(::ActiveRecord::Base)
    record.reload
  end
end
```

### Default Modifiers

It's possible to configure the default modifiers used for all `let_it_be` calls:

- Globally:

```ruby
TestProf::LetItBe.configure do |config|
  # Make refind activated by default
  config.default_modifiers[:refind] = true
end
```

- For specific contexts using tags:

```ruby
context "with let_it_be reload", let_it_be_modifiers: {reload: true} do
  # examples
end
```

**NOTE:** Nested contexts tags are overwritten not merged:

```ruby
TestProf::LetItBe.configure do |config|
  config.default_modifiers[:freeze] = false
end

context "with reload", let_it_be_modifiers: {reload: true} do
  # uses freeze: false, reload: true here

  context "with freeze", let_it_be_modifiers: {freeze: true} do
    # uses only freeze: true (reload: true is overwritten by new metadata)
  end
end
```

## State Leakage Detection

From [`rspec-rails` docs](https://relishapp.com/rspec/rspec-rails/v/3-9/docs/transactions) on transactions and `before(:context)`:

> Even though database updates in each example will be rolled back, the object won't know about those rollbacks so the object and its backing data can easily get out of sync.

Since `let_it_be` initialize objects in `before(:context)` hooks under the hood, it's affected by this problem: the code might modify models shared between examples (thus causing _shared state leaks_). That could happen unwillingly: when the underlying code under test modifies models, e.g. modifies `updated_at` attribute; or deliberately: when models are updated in `before` hooks or examples themselves instead of creating models in a proper state initially.

This state leakage comes with potentially harmful side effects on the other examples, such as implicit dependencies and execution order dependency.

With many shared models between many examples, it's hard to track down the example and exact place in the code that modifies the model.

To detect modifications, objects that are passed to `let_it_be` are frozen (with `#freeze`), and `FrozenError` is raised:

```ruby
# use freeze: true modifier to enable this feature
let_it_be(:user, freeze: true) { create(:user) }

# it is almost equal to
before_all { @user = create(:user).freeze }
let(:user) { @user }
```

To fix the `FrozenError`:

- Add `reload: true`/`refind: true`, it pacifies leakage detection and prevents leakage itself. Typically it's significantly faster to reload the model than to re-create it from scratch before each example (two or even three orders of magnitude faster in some cases).
- Rewrite the problematic test code.

This feature is opt-in, since it may find a significant number of leakages in specs that may be a significant burden to fix all at once.
It's possible to gradually turn it on for parts of specs (e.g., only models) by using:

```ruby
# spec/spec_helper.rb
RSpec.configure do |config|
  # ...
  config.define_derived_metadata(let_it_be_frost: true) do |metadata|
    metadata[:let_it_be_modifiers] ||= {freeze: true}
  end
end
```

And then tag contexts/examples with `:let_it_be_frost` to enable this feature.

Alternatively, you can specify `freeze` modifier explicitly (`let_it_be(freeze: true)`) or configure an alias.
