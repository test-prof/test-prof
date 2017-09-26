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
      FactoryGirl.create(:account)

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

## Caveats

`AnyFixture` cleans tables in the reversed order, in which they were registered. This
means, that if you register a fixture, which references a not-yet-registed table, a
foreign-key violation error *might* occur. An example is worth more than 1000
words:

```ruby
class Author < ApplicationRecord
  has_many :articles
end

class Article < ApplicationRecord
  belongs_to :author
end
```

The usual usage of would be:

1. Register the shared contexts:

```ruby
RSpec.shared_context "author" do
  before(:all) do
    @author = TestProf::AnyFixture.register(:author) do
      FactoryGirl.create(:account)
    end
  end

  let(:author) { @author }
end

RSpec.shared_context "article" do
  before(:all) do
    @article = TestProf::AnyFixture.register(:article) do
      FactoryGirl.create(:article, author: @author)
    end
  end

  let(:article) { @article }
end
```

2. Include the contexts into a spec file:

```ruby
include_context 'author'
include_context 'article'
```

If one forgets to include the `author` context or includes it after the `article` context,
an error will be raised. At the end of the suite, first the `articles` and then the
`authors` table will be cleaned.

Here is another example of the `artcile` shared context:

```ruby
RSpec.shared_context "article" do
  before(:all) do
    author = FactoryGirl.create(:author)

    @article = TestProf::AnyFixture.register(:article) do
      FactoryGirl.create(:article, author: author)
    end
  end

  let(:article) { @article }
end
```

In this case, even if one doesn't include the `author` context, the test would pass. In
case, the `author` context is later registered (in another test), at the end of the
suite first the `authors` and then the `articles` table will be cleaned, which will lead
to a foreign-key violation error.
