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

`AnyFixture` cleans tables in the reverse order as compared to the order they were populated. That
means when you register a fixture which references a not-yet-registered table, a
foreign-key violation error *might* occur (if any). An example is worth more than 1000
words:

```ruby
class Author < ApplicationRecord
  has_many :articles
end

class Article < ApplicationRecord
  belongs_to :author
end
```

And the shared contexts:

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
    # outside of AnyFixture, we don't know about its dependent tables
    author = FactoryGirl.create(:author)

    @article = TestProf::AnyFixture.register(:article) do
      FactoryGirl.create(:article, author: author)
    end
  end

  let(:article) { @article }
end
```

Then in some example:

```ruby
# This one adds only the 'articles' table to the list of affected tables
include_context "article"
# And this one adds the 'authors' table
include_context "author"
```

Now we have the following affected tables list: `["articles", "authors"]`. At the end of the suite, the "authors" table is cleaned first which leads to a foreign-key violation error.
