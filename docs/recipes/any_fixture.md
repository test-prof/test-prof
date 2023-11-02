# AnyFixture

Fixtures are a great way to increase your test suite performance, but for a large project, they are very hard to maintain.

We propose a more general approach to lazy-generate the _global_ state for your test suite – AnyFixture.

With AnyFixture, you can use any block of code for data generation, and it will take care of cleaning it out at the end of the run.

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
      FactoryBot.create(:account)

      # or with Fabrication
      Fabricate(:account)

      # or with plain old AR
      Account.create!(name: "test")
    end
  end

  # Use .register here to track the usage stats (see below)
  let(:account) { TestProf::AnyFixture.register(:account) }

  # Or hard-reload object if there is chance of in-place modification
  let(:account) { Account.find(TestProf::AnyFixture.register(:account).id) }
end

# You can enhance the existing database cleaning. Posts will be deleted before fixtures reset
TestProf::AnyFixture.before_fixtures_reset do
  Post.delete_all
end

# Or after reset
TestProf::AnyFixture.after_fixtures_reset do
  Post.delete_all
end

# Then in your tests

# Active this fixture using a tag
describe UsersController, :account do
  # ...
end

# This test also uses the same account record,
# no double-creation
describe PostsController, :account do
  # ...
end
```

See real life [example](http://bit.ly/any-fixture).

## Instructions

### RSpec

In your `spec_helper.rb` (or `rails_helper.rb` if you have one):

```ruby
require "test_prof/recipes/rspec/any_fixture"
```

Now you can use `TestProf::AnyFixture` in your tests.

### Minitest

When using AnyFixture with Minitest, you should take care of cleaning the database after each test run by yourself. For example:

```ruby
# test_helper.rb

require "test_prof/any_fixture"

at_exit { TestProf::AnyFixture.clean }
```

## DSL

We provide an optional _syntactic sugar_ (through Refinement) to make it easier to define fixtures and use callbacks:

```ruby
require "test_prof/any_fixture/dsl"

# Enable DSL
using TestProf::AnyFixture::DSL

# and then you can use `fixture` method (which is just an alias for `TestProf::AnyFixture.register`)
before(:all) { fixture(:account) }

# You can also use it to fetch the record (instead of storing it in instance variable)
let(:account) { fixture(:account) }

# You can just use `before_fixtures_reset` or `after_fixtures_reset` callbacks
before_fixtures_reset { Post.delete_all }
after_fixtures_reset { Post.delete_all }
```

## `ActiveRecord#refind`

TestProf also provides an extension to _hard-reload_ ActiveRecord objects:

```ruby
# instead of
let(:account) { Account.find(fixture(:account).id) }

# load refinement
require "test_prof/ext/active_record_refind"

using TestProf::Ext::ActiveRecordRefind

let(:account) { fixture(:account).refind }
```

## Temporary disable fixtures

Some of your tests might rely on _clean database_. Thus running them along with AnyFixture-dependent tests, could produce failures.

You can disable (or delete) all created fixture while running a specified example or group using the `:with_clean_fixture` shared context:

```ruby
context "global state", :with_clean_fixture do
  # or include explicitly
  # include_context "any_fixture:clean"

  specify "table is empty or smth like this" do
    # ...
  end
end
```

How does it work? It wraps the example group into a transaction (using [`before_all`](./before_all.md)) and calls `TestProf::AnyFixture.clean` before running the examples.

Thus, this context is a little bit _heavy_. Try to avoid such situations and write specs independent of the global state.

## Usage report

`AnyFixture` collects the usage information during the test run and could report it at the end:

```sh
[TEST PROF INFO] AnyFixture usage stats:

       key    build time  hit count    saved time

      user     00:00.004          4     00:00.017
      post     00:00.002          1     00:00.002

Total time spent: 00:00.006
Total time saved: 00:00.019
Total time wasted: 00:00.000
```

The reporting is off by default, to enable the reporting set `TestProf::AnyFixture.config.reporting_enabled = true` (or you can invoke it manually through `TestProf::AnyFixture.report_stats`).

You can also enable reporting through the `ANYFIXTURE_REPORT=1` env variable.

## Using auto-generated SQL dumps

> @since v1.0, experimental

AnyFixture is designed to generate data once per a test suite run (and cleanup in the end). It still could be time-consuming (e.g., for system or performance tests); thus, we want to optimize further.

We provide another way of speeding up test data called `#register_dump`. It works similarly to `#register` for the first run: it accepts a block of code and tracks SQL queries made within it. Then, it generates a plain SQL dump representing the data creating or modified during the call and uses this dump to restore the database state for the subsequent test runs.

Let's consider an example:

```ruby
RSpec.shared_context "account", account: true do
  # You should call AnyFixture outside of transaction to re-use the same
  # data between examples
  before(:all) do
    # The block is called once per test run (similary to #register)
    TestProf::AnyFixture.register_dump("account") do
      # Do anything here, AnyFixture keeps track of affected DB tables
      # For example, you can use factories here
      account = FactoryBot.create(:account, name: "test")

      # or with Fabrication
      account = Fabricate(:account, name: "test")

      # or with plain old AR
      account = Account.create!(name: "test")

      # updates are also tracked
      account.update!(tag: "sql-dump")
    end
  end

 # Here, we MUST use a custom way to retrieve a record: since we restore the data
 # from a plain SQL dump, we have no knowledge of Ruby objects
  let(:account) { Account.find_by!(name: "test") }
end
```

And that's what happened when we run tests:

```sh
# first run
$ bundle exec rspec

# AnyFixture.register_dump is called:
# - is SQL dump present? No
# - run block and write all modifying queries to a new SQL dump
# AnyFixture.clean is called:
# - clean all the affected tables

# second run
$ bundle exec rspec

# AnyFixture.register_dump is called:
# - is SQL dump present? Yes
# - restore dump (do not run block)
# AnyFixture.clean is called:
# - clean all the affected tables
```

### Requirements

Currently, only PostgreSQL 12+ and SQLite3 are supported.

### Dump invalidation

The generated dump could become out of date for many reasons: database schema changed, fixture block has been updated, etc.
To deal with invalidation, we use file content digests as _cache keys_ (dump file name suffixes).

By default, AnyFixture _watches_ `db/schema.rb`, `db/structure.sql` and the file that calls `#register_dump`.

The list of default watch files could be updated by modifying the `default_dump_watch_paths` configuration parameter:

```ruby
TestProf::AnyFixture.configure do |config|
  # you can use exact file paths or globs
  config.default_dump_watch_paths << Rails.root.join("spec/factories/**/*")
end
```

Also, you add watch files to a specific `#register_dump` call via the `watch` option:

```ruby
TestProf::AnyFixture.register_dump("account", watch: ["app/models/account.rb", "app/models/account/**/*,rb"]) do
  # ...
end
```

**NOTE:** When you use the `watch` option, the current file is not added to the watch list. You should use `__FILE__` explicitly for that.

Finally, if you want to forcefully re-generate a dump, you can use the `ANYFIXTURE_FORCE_DUMP` environment variable:

- `ANYFIXTURE_FORCE_DUMP=1` will force all dumps regeneration.
- `ANYFIXTURE_FORCE_DUMP=account` will force regeneration only of the matching dumps (i.e., matching `/account/`).

#### Cache keys

It's possible to provide custom cache keys to be used as a part of a digest:

```ruby
# cache_key could be pretty much anything that responds to #to_s
TestProf::AnyFixture.register_dump("account", cache_key: ["str", 1, {key: :val}]) do
  # ...
end
```

### Hooks

#### `before` / `after`

Before hooks are called either before calling a fixture block or before restoring a dump.
One particular use case is to re-create a tenant in a multi-tenant app:

```ruby
TestProf::AnyFixture.register_dump(
  "account",
  before: proc do
    begin
      Apartment::Tenant.create("test")
    rescue
      nil
    end
    Apartment::Tenant.create("test")
  end
) do
  # ...
end
```

Similarly, after hooks are called either after calling a fixture block or after restoring a dump.

You can also specify global before and after hooks:

```ruby
TestProf::AnyFixture.configure do |config|
  config.before_dump do |dump:, import:|
    # dump is an object containing information about the dump (e.g., dump.digest)
    # import is true if we're restoring a dump and false otherwise
    # do something
  end

  config.after_dump do |dump:, import:|
    # ...
  end
end
```

**NOTE**: after callbacks are always executed, even if dump creation failed. You can use the `dump.success?` method to determine whether data generation succeeds or not.

#### `skip_if`

This callback is available only as of the `#register_dump` option and could be used to ignore the fixture completely. This is useful when you want to preserve the database state between test runs (i.e., do not clean the DB).

Here is a complete example:

```ruby
TestProf::AnyFixture.register_dump(
  "account",
  # do not track tables for AnyFixture.clean (though other fixtures could affect this)
  clean: false,
  skip_if: proc do |dump:|
    Apartment::Tenant.switch!("test")
    # if the current account has matching meta — the database is in actual state
    Account.find_by!(name: "test").meta["dump-version"] == dump.digest
  end,
  before: proc do
    begin
      Apartment::Tenant.create("test")
    rescue
      nil
    end
    Apartment::Tenant.create("test")
  end,
  after: proc do |dump:, import:|
    # do not persist dump version if dump failed or we're restoring data
    next if import || !dump.success?

    Account.find_by!(name: "test").then do |account|
      account.meta["dump-version"] = dump.digest
      account.save!
    end
  end
) do
  # ...
end
```

### Configuration

There a few more configuration options available:

```ruby
TestProf::AnyFixture.configure do |config|
  # Where to store dumps (by default, TestProf.artifact_path + '/any_dumps')
  config.dumps_dir = "any_dumps"
  # Include mathing queries into a dump (in addition to INSERT/UPDATE/DELETE queries)
  config.dump_matching_queries = /^$/
  # Whether to try using CLI tools such as psql or sqlite3 to restore dumps or not (and use ActiveRecord instead)
  config.import_dump_via_cli = false
end
```

**NOTE:** When using CLI tools to restore dumps, it's not possible to track affected tables and thus clean them via `AnyFixture.clean`.
