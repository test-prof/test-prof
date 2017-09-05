# Factory Doctor

One common bad pattern that slows our tests down is unnecessary database manipulation. Consider a _bad_ example:

```ruby
it "validates name presence" do
  user = create(:user)
  user.name = ''
  expect(user).not_to be_valid
end
```

Here we create a new user record, run all callbacks and validations and save it to the database. We don't need all these! Here is a _good_ example:

```ruby
it "validates name presence" do
  user = build_stubbed(:user)
  user.name = ''
  expect(user).not_to be_valid
end
```

Read more about [`build_stubbed`](https://robots.thoughtbot.com/use-factory-girls-build-stubbed-for-a-faster-test).

FactoryDoctor is a tool that helps you identify such _bad_ tests, i.e. tests that perform unnecessary database queries.

Example output:

```sh
[TEST PROF INFO] FactoryDoctor report

Total (potentially) bad examples: 2
Total wasted time: 00:13.165

User (./spec/models/user_spec.rb:3)
  validates name (./spec/user_spec.rb:8) – 1 record created, 00:00.114
  validates email (./spec/user_spec.rb:8) – 2 records created, 00:00.514
```

**NOTE**: have you noticed the "potentially" word? Unfortunately, FactoryDoctor is not a 
magician (it's still learning) and sometimes it produces false negatives and false positives too.

Please, submit an [issue](https://github.com/palkan/test-prof/issues) if you found a case which makes FactoryDoctor fail.

You can also tell FactoryDoctor to ignore specific examples/groups. Just add `:fd_ignore` tag to it:

```ruby
# won't be reported as offense
it "is ignored", :fd_ignore do
  user = create(:user)
  user.name = ''
  expect(user).not_to be_valid
end
```

## Instructions

Currently, FactoryDoctor works only with FactoryGirl and RSpec.

To activate FactoryDoctor use `FDOC` environment variable:

```sh
FDOC=1 rspec ...
```

## Using with RSpecStamp

FactoryDoctor can be used with [RSpec Stamp](https://github.com/palkan/test-prof/tree/master/guides/rspec_stamp.md) to automatically mark _bad_ examples with custom tags. For example:

```sh
FDOC=1 FDOC_STAMP="fdoc:consider" rspec ...
```

After running the command above all _potentially_ bad examples would be marked with the `fdoc: :consider` tag.
