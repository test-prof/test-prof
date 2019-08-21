# Verbose Logging

Sometimes digging through logs is the best way to figure out what's going on.

When you run your test suite, logs are not printed out by default (although written to `test.log` – who cares?).

We provide a recipe to turn verbose logging for a specific example/group.

**NOTE:** Rails only.

## Instructions

Drop this line to your `rails_helper.rb` / `spec_helper.rb` / `test_helper.rb` / whatever:

```ruby
require "test_prof/recipes/logging"
```

### Log everything

To turn on logging globally use `LOG` env variable:

```sh
# log everything to stdout
LOG=all rspec ...

# or
LOG=all rake test

# log only Active Record statements
LOG=ar rspec ...
```

### Per-example logging

**NOTE:** RSpec only.

Activate logging by adding special tag – `:log`:

```ruby
# Add the tag and you will see a lot of interesting stuff in your console
it "does smthng weird", :log do
  # ...
end

# or for the group
describe "GET #index", :log do
  # ...
end
```

To enable only Active Record log use `log: :ar` tag:

```ruby
describe "GET #index", log: :ar do
  # ...
end
```

### Logging helpers

For more granular control you can use `with_logging` (log everything) and
`with_ar_logging` (log Active Record) helpers:

```ruby
it "does somthing" do
  do_smth
  # show logs only for the code within the block
  with_logging do
    # ...
  end
end
```

**NOTE:** in order to use this helpers with Minitest you should include the `TestProf::Rails::LoggingHelpers` module manually:

```ruby
class MyLoggingTest < Minitest::Test
  include TestProf::Rails::LoggingHelpers
end
```
