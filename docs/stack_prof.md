# Profiling with StackProf

[StackProf](https://github.com/tmm1/stackprof) is a sampling call-stack profiler for ruby.

## Instructions

Install `stackprof` gem (>= 0.2.9):

```ruby
# Gemfile
group :development, :test do
  gem 'stackprof', '>= 0.2.9', require: false
end
```

StackProf profiler has 2 modes: `global` and `per-example`.

You can activate global profiling using the environment variable `TEST_STACK_PROF`:

```sh
TEST_STACK_PROF=1 bundle exec rake test

# or for RSpec
TEST_STACK_PROF=1 rspec ...
```

Or in your code:

```ruby
TestProf::StackProf.run
```

TestProf provides a built-in shared context for RSpec to profile examples individually:

```ruby
it 'is doing heavy stuff', :sprof do
  # ...
end
```

## Configuration

You can change StackProf mode (which is `wall` by default) through `TEST_STACK_PROF_MODE` env variable.

If you want to generate flame graphs you should collect _raw_ data. Turn _raw_ collection on by passing `TEST_STACK_PROF=raw`.

See [stack_prof.rb](https://github.com/palkan/test-prof/tree/master/lib/test_prof/stack_prof.rb) for all available configuration options and their usage.

## Profiling application boot

The application boot time could also makes testing slower. Try to profile your boot process with StackProf using the following command:

```sh
TEST_STACK_PROF=boot TEST_STACK_PROF_RAW=1 rspec ./spec/some_spec.rb
```

**NOTE:** we recommend to anylize the boot time using flame graphs, that's why we need a `TEST_STACK_PROF_RAW=1` option.
