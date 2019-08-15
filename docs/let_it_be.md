# Let It Be!

Let's bring a little bit of magic and introduce a new way to setup a _shared_ test data.

Suppose you have the following setup:

```ruby
describe BeatleWeightedSearchQuery do
  let!(:paul) { create(:beatle, name: 'Paul') }
  let!(:ringo) { create(:beatle, name: 'Ringo') }
  let!(:george) { create(:beatle, name: 'George') }
  let!(:john) { create(:beatle, name: 'John') }

  specify { expect(subject.call('john')).to contain_exactly(john) }

  # and more examples here
end
```

We don't need to re-create the Fab Four for every example, do we?

We already have [`before_all`](./before_all.md) to solve the problem of _repeatable_ data:

```ruby
describe BeatleWeightedSearchQuery do
  before_all do
    @paul = create(:beatle, name: 'Paul')
    # ...
  end

  specify { expect(subject.call('joh')).to contain_exactly(@john) }

  # ...
end
```

That technique works pretty good but requires us to use instance variables and define everything at once. Thus it's not easy to refactor existing tests which use `let/let!` instead.

With `let_it_be` you can do the following:

```ruby
describe BeatleWeightedSearchQuery do
  let_it_be(:paul) { create(:beatle, name: 'Paul') }
  let_it_be(:ringo) { create(:beatle, name: 'Ringo') }
  let_it_be(:george) { create(:beatle, name: 'George') }
  let_it_be(:john) { create(:beatle, name: 'John') }

  specify { expect(subject.call('john')).to contain_exactly(john) }

  # and more examples here
end
```

That's it! Just replace `let!` with `let_it_be`. That's equal to the `before_all` approach but requires less refactoring.

## Instructions

In your `spec_helper.rb`:

```ruby
require 'test_prof/recipes/rspec/let_it_be'
```

In your tests:

```ruby
describe MySuperDryService do
  let_it_be(:user) { create(:user) }

  # ...
end
```

## Caveats & Modifers

If you modify objects generated within a `let_it_be` block in your examples, you maybe have to re-initiate them.
We have a built-in _modifiers_ support for that:

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

(**@since v0.10.0**) You can also use modifiers with array values, e.g. `create_list`:

```ruby
let_it_be(:posts, reload: true) { create_list(:post, 3) }

# it's the same as
before_all { @posts = create_list(:post, 3) }
let(:posts) { @posts.map(&:reload) }
```

### Custom modifiers

> @since v0.10.0

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

## Aliases

> @since v0.9.0

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
