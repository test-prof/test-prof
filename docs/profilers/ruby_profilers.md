# Using with Ruby profilers

Test Prof allows you to use general Ruby profilers to profile test suites without needing to write any profiling code yourself.
Just install the profiler library and run your tests!

Supported profilers:

- [StackProf](#stackprof)
- [Vernier](#vernier)
- [RubyProf](#rubyprof)

## StackProf

[StackProf][] is a sampling call-stack profiler for Ruby.

Make sure you have `stackprof` in your dependencies:

```ruby
# Gemfile
group :development, :test do
  gem "stackprof", ">= 0.2.9", require: false
end
```

### Profiling the whole test suite with StackProf

**NOTE:** It's recommended to use [test sampling](../recipes/tests_sampling.md) to generate smaller profiling reports.

You can activate StackProf profiling by setting the `TEST_STACK_PROF` env variable:

```sh
TEST_STACK_PROF=1 bundle exec rake test

# or for RSpec
TEST_STACK_PROF=1 bundle exec rspec ...
```

At the end of the test run, you will see the message from Test Prof including paths to generated reports (raw StackProf format and JSON):

```sh
...

[TEST PROF INFO] StackProf report generated: tmp/test_prof/stack-prof-report-wall-raw-total.dump
[TEST PROF INFO] StackProf JSON report generated: tmp/test_prof/stack-prof-report-wall-raw-total.json
```

We recommend uploading JSON reports to [Speedscope][] and analyze flamegraphs. Otherwise, feel free to use the `stackprof` CLI
to manipulate the raw report.

### Profiling individual examples with StackProf

Test Prof provides a built-in shared context for RSpec to profile examples individually:

```ruby
it "is doing heavy stuff", :sprof do
  # ...
end
```

**NOTE:** per-example profiling doesn't work when the global (per-suite) profiling is activated.

### Profiling application boot with StackProf

The application boot time could also makes testing slower. Try to profile your boot process with StackProf using the following command:

```sh
# pick some random spec (1 is enough)
$ TEST_STACK_PROF=boot bundle exec rspec ./spec/some_spec.rb

...
[TEST PROF INFO] StackProf report generated: tmp/test_prof/stack-prof-report-wall-raw-boot.dump
[TEST PROF INFO] StackProf JSON report generated: tmp/test_prof/stack-prof-report-wall-raw-boot.json
```

### StackProf configuration

You can change StackProf mode (which is `wall` by default) through `TEST_STACK_PROF_MODE` env variable.

You can also change StackProf interval through `TEST_STACK_PROF_INTERVAL` env variable.
For modes `wall` and `cpu`, `TEST_STACK_PROF_INTERVAL` represents microseconds and will default to 1000 as per `stackprof`.
For mode `object`, `TEST_STACK_PROF_INTERVAL` represents allocations and will default to 1 as per `stackprof`.

You can disable garbage collection frames by setting `TEST_STACK_PROF_IGNORE_GC` env variable.
Garbage collection time will still be present in the profile but not explicitly marked with
its own frame.

See [stack_prof.rb](https://github.com/test-prof/test-prof/tree/master/lib/test_prof/stack_prof.rb) for all available configuration options and their usage.

## Vernier

[Vernier][] is next generation sampling profiler for Ruby. Give it a try and see if it can help in identifying test peformance bottlenecks!

Make sure you have `vernier` in your dependencies:

```ruby
# Gemfile
group :development, :test do
  gem "vernier", ">= 0.3.0", require: false
end
```

### Profiling the whole test suite with Vernier

**NOTE:** It's recommended to use [test sampling](../recipes/tests_sampling.md) to generate smaller profiling reports.

You can activate Verner profiling by setting the `TEST_VERNIER` env variable:

```sh
TEST_VERNIER=1 bundle exec rake test

# or for RSpec
TEST_VERNIER=1 bundle exec rspec ...
```

At the end of the test run, you will see the message from Test Prof including the path to the generated report:

```sh
...

[TEST PROF INFO] Vernier report generated: tmp/test_prof/vernier-report-wall-raw-total.json
```

Use the [profile-viewer](https://github.com/tenderlove/profiler/tree/ruby) gem or upload your profiles to [profiler.firefox.com](https://profiler.firefox.com).

### Profiling individual examples with Vernier

Test Prof provides a built-in shared context for RSpec to profile examples individually:

```ruby
it "is doing heavy stuff", :vernier do
  # ...
end
```

**NOTE:** per-example profiling doesn't work when the global (per-suite) profiling is activated.

### Profiling application boot with Vernier

You can also profile your application boot process:

```sh
# pick some random spec (1 is enough)
TEST_VERNIER=boot bundle exec rspec ./spec/some_spec.rb
```

## RubyProf

Easily integrate the power of [ruby-prof](https://github.com/ruby-prof/ruby-prof) into your test suite.

Make sure `ruby-prof` is installed:

```ruby
# Gemfile
group :development, :test do
  gem "ruby-prof", ">= 1.4.0", require: false
end
```

### Profiling the whole test suite with RubyProf

**NOTE:** It's highly recommended to use [test sampling](../recipes/tests_sampling.md) to generate smaller profiling reports and avoid slow test runs (RubyProf has a signifact overhead).

You can activate the global profiling using the environment variable `TEST_RUBY_PROF`:

```sh
TEST_RUBY_PROF=1 bundle exec rake test

# or for RSpec
TEST_RUBY_PROF=1 bundle exec rspec ...
```

At the end of the test run, you will see the message from Test Prof including paths to generated reports:

```sh
[TEST PROF INFO] RubyProf report generated: tmp/test_prof/ruby-prof-report-flat-wall-total.txt
```

### Profiling individual examples with RubyProf

TestProf provides a built-in shared context for RSpec to profile examples individually:

```ruby
it "is doing heavy stuff", :rprof do
  # ...
end
```

**NOTE:** per-example profiling doesn't work when the global profiling is activated.

### RubyProf configuration

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

See [ruby_prof.rb](https://github.com/test-prof/test-prof/tree/master/lib/test_prof/ruby_prof.rb) for all available configuration options and their usage.

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

[StackProf]: https://github.com/tmm1/stackprof
[Speedscope]: https://www.speedscope.app
[Vernier]: https://github.com/jhawthorn/vernier
