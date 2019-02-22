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

**NOTE**: requires RSpec >= 3.3.0.

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

## Caveats

If you modify objects generated within a `let_it_be` block in your examples, you maybe have to re-initiate them.
We have a built-in support for that:


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
