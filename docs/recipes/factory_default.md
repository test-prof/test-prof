# FactoryDefault

_FactoryDefault_ aims to help you cope with _factory cascades_ (see [FactoryProf](../profilers/factory_prof.md)) by reusing associated records.

**NOTE**. Only works with FactoryGirl/FactoryBot.

It can be very useful when you're working on a typical SaaS application (or other hierarchical data).

Consider an example. Assume we have the following factories:

```ruby
factory :account do
end

factory :user do
  account
end

factory :project do
  account
  user
end

factory :task do
  account
  project
  user
end
```

And we want to test the `Task` model:

```ruby
describe "PATCH #update" do
  let(:task) { create(:task) }

  it "works" do
    patch :update, id: task.id, task: {completed: "t"}
    expect(response).to be_success
  end

  # ...
end
```

How many users and accounts are created per example? Two and four respectively.

And it breaks our logic (every object should belong to the same account).

Typical workaround:

```ruby
describe "PATCH #update" do
  let(:account) { create(:account) }
  let(:project) { create(:project, account: account) }
  let(:task) { create(:task, project: project, account: account) }

  it "works" do
    patch :update, id: task.id, task: {completed: "t"}
    expect(response).to be_success
  end
end
```

That works. And there are some cons: it's a little bit verbose and error-prone (easy to forget something).

Here is how we can deal with it using FactoryDefault:

```ruby
describe "PATCH #update" do
  let(:account) { create_default(:account) }
  let(:project) { create_default(:project) }
  let(:task) { create(:task) }

  # and if we need more projects, users, tasks with the same parent record,
  # we just write
  let(:another_project) { create(:project) } # uses the same account
  let(:another_task) { create(:task) } # uses the same account

  it "works" do
    patch :update, id: task.id, task: {completed: "t"}
    expect(response).to be_success
  end
end
```

**NOTE**. This feature introduces a bit of _magic_ to your tests, so use it with caution ('cause tests should be human-readable first). Good idea is to use defaults for top-level entities only (such as tenants in multi-tenancy apps).

## Instructions

In your `spec_helper.rb`:

```ruby
require "test_prof/recipes/rspec/factory_default"
```

This adds two new methods to FactoryBot:

- `FactoryBot#set_factory_default(factory, object)` – use the `object` as default for associations built with `factory`

Example:

```ruby
let(:user) { create(:user) }

before { FactoryBot.set_factory_default(:user, user) }
```

- `FactoryBot#create_default(factory, *args)` – is a shortcut for `create` + `set_factory_default`.

**IMPORTANT:** Defaults are **cleaned up after each example** by default (i.e., when using `test_prof/recipes/rspec/factory_default`).

### Using with `before_all` / `let_it_be`

Defaults created within `before_all` and `let_it_be` are not reset after each example, but only at the end of the corresponding example group. So, it's possible to call `create_default` within `let_it_be` without any additional configuration. **RSpec only**

**IMPORTANT:** You must load FactoryDefault after loading BeforeAll to make this feature work.

**NOTE**. Regular `before(:all)` callbacks are not supported.

### Working with traits

You can use traits in your associations, for example:

```ruby
factory :comment do
  user
end

factory :post do
  association :user, factory: %i[user able_to_post]
end

factory :view do
  association :user, factory: %i[user unable_to_post_only_view]
end
```

If there is a default value for the `user` factory, it's gonna be used independently of traits. This may break your logic.

To prevent this, configure FactoryDefault to preserve traits:

```ruby
# Globally
TestProf::FactoryDefault.configure do |config|
  config.preserve_traits = true
end

# or in-place
create_default(:user, preserve_traits: true)
```

Creating a default with trait works as follows:

```ruby
# Create a default with trait
user = create_default(:user_poster, :able_to_post)

# When an association has no traits specified, the default with trait is used
create(:comment).user == user #=> true
# When an association has the matching trait specified, the default is used, too
create(:post).user == user #=> true
# When the association's trait differs, default is skipped
create(:view).user == user #=> false
```

### Handling attribute overrides

It's possible to define attribute overrides for associations:

```ruby
factory :post do
  association :user, name: "Poster"
end

factory :view do
  association :user, name: "Viewer"
end
```

FactoryDefault ignores such overrides and still returns a default `user` record (if created). You can turn the attribute awareness feature on to skip the default record if overrides don't match the default object attributes:

```ruby
# Globally
TestProf::FactoryDefault.configure do |config|
  config.preserve_attributes = true
end

# or in-place
create_default :user, preserve_attributes: true
```

**NOTE:** In the future versions of Test Prof, both `preserve_traits` and `preserve_attributes` will default to true. We recommend settings them to true if you just starting using this feature.

### Ignoring default factories

You can temporary disable the defaults usage by wrapping a code with the `skip_factory_default` method:

```ruby
account = create_default(:account)
another_account = skip_factory_default { create(:account) }

expect(another_account).not_to eq(account)
```

### Showing usage stats

You can display the FactoryDefault usage stats by setting the `FACTORY_DEFAULT_SUMMARY=1` or `FACTORY_DEFAULT_STATS=1` env vars or by setting the configuration values:

```ruby
TestProf::FactoryDefault.configure do |config|
  config.report_summary = true
  # Report stats prints the detailed usage information (including summary)
  config.report_stats = true
end
```

For example:

```sh
$ FACTORY_DEFAULT_SUMMARY=1 bundle exec rspec

FactoryDefault summary: hit=11 miss=3
```

Where `hit` indicates the number of times the default factory value was used instead of a new one when an association was created; `miss` indicates the number of time the default value was ignored due to traits or attributes mismatch.

## Factory Default profiling, or when to use defaults

Factory Default ships with the profiler, which can help you to see how associations are being used in your test suite, so you can decide on using `create_default` or not.

To enable profiling, run your tests with the `FACTORY_DEFAULT_PROF=1` set:

```sh
$ FACTORY_DEFAULT_PROF=1 bundle exec rspec spec/some/file_spec.rb

.....

[TEST PROF INFO] Factory associations usage:

               factory      count    total time

                  user         17     00:42.010
         user[traited]         15     00:31.560
  user{tag:"some tag"}          1     00:00.205

Total associations created: 33
Total uniq associations created: 3
Total time spent: 01:13.775
```

Since default factories are usually registered per an example group (or test class), we recommend running this profiler against a particular file, so you can quickly identify the possibility of adding `create_default` and improve the tests speed.

**NOTE:** You can also use the profiler to measure the effect of adding `create_default`; for that, compare the results of running the profiler with FactoryDefault enabled and disabled (you can do that by passing the `FACTORY_DEFAULT_DISABLED=1` env var).
