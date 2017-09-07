# Profiling with RubyProf

Easily integrate the power of [ruby-prof](https://github.com/ruby-prof/ruby-prof) into your test suite.

## Instructions

Install `ruby-prof` gem (>= 0.16):

```ruby
# Gemfile
group :development, :test do
  gem 'ruby-prof', '>= 0.16.0', require: false
end
```

RubyProf profiler has two modes: _global_ and _per-example_.

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
  ...
end
```

### Configuration

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

Also, you can specify RubyProf mode (`wall`, `cpu`, etc) through `TEST_RUBY_PROF_MODE` env variable.

See [ruby_prof.rb](https://github.com/palkan/test-prof/tree/master/lib/test_prof/ruby_prof.rb) for all available configuration options and their usage.
