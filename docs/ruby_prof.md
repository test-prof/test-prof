# Profiling with RubyProf

Easily integrate the power of [ruby-prof](https://github.com/ruby-prof/ruby-prof) into your test suite.

## Instructions

Install `ruby-prof` gem (>= 0.17):

```ruby
# Gemfile
group :development, :test do
  gem "ruby-prof", ">= 0.17.0", require: false
end
```

RubyProf profiler has two modes: `global` and `per-example`.

You can activate the global profiling using the environment variable `TEST_RUBY_PROF`:

```sh
TEST_RUBY_PROF=1 bundle exec rake test

# or for RSpec
TEST_RUBY_PROF=1 rspec ...
```

Or in your code:

```ruby
TestProf::RubyProf.run
```

TestProf provides a built-in shared context for RSpec to profile examples individually:

```ruby
it "is doing heavy stuff", :rprof do
  # ...
end
```

**NOTE:** per-example profiling doesn't work when the global profiling is activated.

## Configuration

The most useful configuration option is `printer` – it allows you to specify a RubyProf [printer](https://github.com/ruby-prof/ruby-prof#printers).

You can specify a printer through environment variable `TEST_RUBY_PROF`:

```sh
TEST_RUBY_PROF=call_stack bundle exec rake test
```

Or in your code:

```ruby
TestProf::RubyProf.configure do |config|
  config.printer = :call_stack
end
```

By default, we use `FlatPrinter`.

**NOTE:** to specify the printer for per-example profiles use `TEST_RUBY_PROF_PRINTER` env variable ('cause using `TEST_RUBY_PROF` activates the global profiling).

Also, you can specify RubyProf mode (`wall`, `cpu`, etc) through `TEST_RUBY_PROF_MODE` env variable.

See [ruby_prof.rb](https://github.com/palkan/test-prof/tree/master/lib/test_prof/ruby_prof.rb) for all available configuration options and their usage.

### Methods Exclusion

It's useful to exclude some methods from the profile to focus only on the application code.

TestProf uses RubyProf [`exclude_common_methods!`](https://github.com/ruby-prof/ruby-prof/blob/e087b7d7ca11eecf1717d95a5c5fea1e36ea3136/lib/ruby-prof/profile/exclude_common_methods.rb) by default (disable it with `config.exclude_common_methods = false`).

We exclude some other common methods and RSpec specific internal methods by default.
To disable TestProf-defined exclusions set `config.test_prof_exclusions_enabled = false`.

You can specify custom exclusions through `config.custom_exclusions`, e.g.:

```ruby
TestProf::RubyProf.configure do |config|
  config.custom_exclusions = {User => %i[save save!]}
end
```
