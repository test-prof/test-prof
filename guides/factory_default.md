# FactoryDefault

_Factory Default_ aims to help you cope with _factory cascades_ (see [FactoryProf](https://github.com/palkan/test-prof/tree/master/guides/factory_prof.md)) by reusing associated records.

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
    patch :update, id: task.id, task: { completed: 't' }
    expect(response).to be_success
  end

  ...
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
    patch :update, id: task.id, task: { completed: 't' }
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
  let(:another_task) { create(:task) } # uses the same account and the first project

  it "works" do
    patch :update, id: task.id, task: { completed: 't' }
    expect(response).to be_success
  end
end
```

*NOTE*. This feature introduces a bit of _magic_ to your tests, so use it with caution ('cause tests should be human-readable first). Good idea is to use defaults for top-level entities only (such as tenants in multi-tenancy apps).

## Instructions

In your `spec_helper.rb`:

```ruby
require "test_prof/recipes/rspec/factory_default"
```

This adds two new methods to FactoryGirl:

- `FactoryGirl#set_factory_default(factory, object)` – use the `object` as default for associations built with `factory`

Example:

```ruby
let(:user) { create(:user) }

before { FactoryGirl.set_factory_default(:user, user) }
```

- `FactoryGirl#create_default(factory, *args)` – is a shortcut for `create` + `set_factory_default`.

*NOTE*. Defaults are cleaned up after each example.
