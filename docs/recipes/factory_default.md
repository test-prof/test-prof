# FactoryDefault

_Factory Default_ aims to help you cope with _factory cascades_ (see [FactoryProf](../profilers/factory_prof.md)) by reusing associated records.

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

**NOTE**. Defaults are **cleaned up after each example** by default. That means you cannot create defaults within `before(:all)` / [`before_all`](./before_all.md) / [`let_it_be`](./let_it_be.md) definitions. That could be changed in the future, for now [check this workaround](https://github.com/test-prof/test-prof/issues/125#issuecomment-471706752).

### Working with traits

When you have traits in your associations like:

```ruby
factory :post do
  association :user, factory: %i[user able_to_post]
end

factory :view do
  association :user, factory: %i[user unable_to_post_only_view]
end
```

and set a default for `user` factory - you will find the same object used in all of the above factories. Sometimes this may break your logic.

To prevent this - set `FactoryDefault.preserve_traits = true` or use per-factory override
`create_default(:user, preserve_traits: true)`. This reverts back to original FactoryBot behavior for associations that have explicit traits defined.
