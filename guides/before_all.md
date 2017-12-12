# Before All

Rails has a great feature – `transactional_tests`, i.e. running each example within a transaction which is roll-backed in the end.

Thus no example polutes global database state.

But what if have a lot of examples with a common setup?

Of course, we can do something like this:

```ruby
describe BeatleWeightedSearchQuery do
  before(:each) do
    @paul = create(:beatle, name: 'Paul')
    @ringo = create(:beatle, name: 'Ringo')
    @george = create(:beatle, name: 'George')
    @john = create(:beatle, name: 'John')
  end

  # and about 15 examples here
end
```

Or you can try `before(:all)`:

```ruby
describe BeatleWeightedSearchQuery do
  before(:all) do
    @paul = create(:beatle, name: 'Paul')
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
    @paul = create(:beatle, name: 'Paul')
    # ...
  end

  # ...
end
```

That's all!

## Instructions

In your `spec_helper.rb`:

```ruby
require 'test_prof/recipes/rspec/before_all'
```

## Caveats

If you modify objects generated within a `before_all` block in your examples, you maybe have to re-initiate them:


```ruby
before_all do
  @user = create(:user)
end

let(:user) { @user }

it 'when user is admin' do
  # we modified our object in-place!
  user.update!(role: 1)
  expect(user).to be_admin
end

it 'when user is regular' do
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
```
