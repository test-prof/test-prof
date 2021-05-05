# Factory Doctor

One common bad pattern that slows our tests down is unnecessary database manipulation. Consider a _bad_ example:

```ruby
# with FactoryBot/FactoryGirl
it "validates name presence" do
  user = create(:user)
  user.name = ""
  expect(user).not_to be_valid
end

# with Fabrication
it "validates name presence" do
  user = Fabricate(:user)
  user.name = ""
  expect(user).not_to be_valid
end
```

Here we create a new user record, run all callbacks and validations and save it to the database. We don't need all these! Here is a _good_ example:

```ruby
# with FactoryBot/FactoryGirl
it "validates name presence" do
  user = build_stubbed(:user)
  user.name = ""
  expect(user).not_to be_valid
end

# with Fabrication
it "validates name presence" do
  user = Fabricate.build(:user)
  user.name = ""
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

User (./spec/models/user_spec.rb:3) (3 records created, 00:00.628)
  validates name (./spec/user_spec.rb:8) – 1 record created, 00:00.114
  validates email (./spec/user_spec.rb:8) – 2 records created, 00:00.514
```

**NOTE**: have you noticed the "potentially" word? Unfortunately, FactoryDoctor is not a
magician (it's still learning) and sometimes it produces false negatives and false positives too.

Please, submit an [issue](https://github.com/test-prof/test-prof/issues) if you found a case which makes FactoryDoctor fail.

You can also tell FactoryDoctor to ignore specific examples/groups. Just add the `:fd_ignore` tag to it:

```ruby
# won't be reported as offense
it "is ignored", :fd_ignore do
  user = create(:user)
  user.name = ""
  expect(user).not_to be_valid
end
```

## Instructions

FactoryDoctor supports:

- FactoryGirl/FactoryBot
- Fabrication.

### RSpec

To activate FactoryDoctor use `FDOC` environment variable:

```sh
FDOC=1 rspec ...
```

### Using with RSpecStamp

FactoryDoctor can be used with [RSpec Stamp](../recipes/rspec_stamp.md) to automatically mark _bad_ examples with custom tags. For example:

```sh
FDOC=1 FDOC_STAMP="fdoc:consider" rspec ...
```

After running the command above all _potentially_ bad examples would be marked with the `fdoc: :consider` tag.

### Minitest

To activate FactoryDoctor use `FDOC` environment variable:

```sh
FDOC=1 ruby ...
```

or use CLI option as shown below:

```sh
ruby ... --factory-doctor
```

The same option to force Factory Doctor to ignore specific examples is also available for Minitest.
Just use `fd_ignore` inside your example:

```ruby
# won't be reported as offense
it "is ignored" do
  fd_ignore

  @user.name = ""
  refute @user.valid?
end
```

### Using with Minitest::Reporters

If you're using `Minitest::Reporters` in your project you have to explicitly declare it
in your test helper file:

```sh
require 'minitest/reporters'
Minitest::Reporters.use! [YOUR_FAVORITE_REPORTERS]
```

**NOTE**: When you have `minitest-reporters` installed as a gem but not declared in your `Gemfile`
make sure to always prepend your test run command with `bundle exec` (but we sure that you always do it).
Otherwise, you'll get an error caused by Minitest plugin system, which scans all the entries in the
`$LOAD_PATH` for any `minitest/*_plugin.rb`, thus initialization of `minitest-reporters` plugin which is
available in that case doesn't happens correctly.

## Configuration

The following configuration parameters are available (showing defaults):

```ruby
TestProf::FactoryDoctor.configure do |config|
  # Which event to track within test example to consider them "DB-dirty"
  config.event = "sql.active_record"
  # Consider result "good" if the time in DB is less then the threshold
  config.threshold = 0.01
end
```

You can use the corresponding env variables as well: `FDOC_EVENT` and `FDOC_THRESHOLD`.
