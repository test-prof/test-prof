# Playbook

This document aims to help you get started with profiling test suites and answers the following questions: which profiles to run first? How do we interpret the results to choose the next steps? Etc.

**NOTE**: This document assumes you're working with a Ruby on Rails application and RSpec testing framework. The ideas can easily be translated into other frameworks.

## Step 0. Configuration basics

Low-hanging configuration fruits:

- Disable logging in tests—it's useless. If you really need it, use our [logging utils](./recipes/logging.md).

```ruby
config.logger = ActiveSupport::TaggedLogging.new(Logger.new(nil))
config.log_level = :fatal
```

- Disable coverage and built-in profiling by default. Use env var to enable it (e.g., `COVERAGE=true`)

## Step 1. General profiling

It helps to identify not-so-low hanging fruits. We recommend using [StackProf](./profilers/stack_prof.md), so you must install it first (if not yet):

```sh
bundle add stackprof
```

Configure Test Prof to generate JSON profiles by default:

```ruby
TestProf::StackProf.configure do |config|
  config.format = "json"
end
```

We recommend using [speedscope](https://www.speedscope.app) to analyze these profiles.

### Step 1.1. Application boot profiling

```sh
TEST_STACK_PROF=boot rspec ./spec/some_spec.rb
```

**NOTE:** running a single spec/test is enough for this profiling.

What to look for? Some examples:

- No [Bootsnap](https://github.com/Shopify/bootsnap) used or not configured to cache everything (e.g., YAML files)
- Slow Rails initializers that are not needed in tests.

### Step 1.2. Sampling tests profiling

The idea is to run a random subset of tests multiple times to reveal some application-wide problems. You must enable the [sampling feature](./recipes/tests_sampling.md) first:

```rb
# For RSpec in your spec_helper.rb
require "test_prof/recipes/rspec/sample"

# For Minitest in your test_helper.rb
require "test_prof/recipes/minitest/sample"
```

Then run **multiple times** and analyze the obtained flamegraphs:

```sh
SAMPLE=100 bin/rails test
# or
SAMPLE=100 bin/rspec
```

Common findings:

- Encryption calls (`*crypt*`-whatever): relax the settings in the test env
- Log calls: are you sure you disabled logs?
- Databases: maybe there are some low-hanging fruits (like using DatabaseCleaner truncation for every test instead of transactions)
- Network: should not be there for unit tests, inevitable for browser tests; use [Webmock](https://github.com/bblimke/webmock) to disable HTTP calls completely.

## Step 2. Narrow down the scope

This is an important step for large codebases. We must prioritize quick fixes that bring the most value (time reduction) over dealing with complex, slow tests individually (even if they're the slowest ones). For that, we first identify the **types of tests** contributing the most to the overall run time.

We use [TagProf](./profilers/tag_prof.md) for that:

```sh
TAG_PROF=type TAG_PROF_FORMAT=html TAG_PROF_EVENT=sql.active_record,factory.create bin/rspec
```

Looking at the generated diagram, you can identify the two most time-consuming test types (usually models and/or controllers among them).

We assume that it's easier to find a common slowness cause for the whole group and fix it than dealing with individual tests. Given that assumption, we continue the process only within the selected group (let's say, models).

## Step 3. Specialized profiling

Within the selected group, we can first perform quick event-based profiling via [EventProf](./profilers/event_prof.md). (Maybe, with sampling enabled as well).

### Step 3.1. Dependencies configuration

At this point, we may identify some misconfigured or misused dependencies/gems. Common examples:

- Inlined Sidekiq jobs:

```sh
EVENT_PROF=sidekiq.inline bin/rspec spec/models
```

- Wisper broadcasts ([patch required](https://gist.github.com/palkan/aa7035cebaeca7ed76e433981f90c07b)):

```sh
EVENT_PROF=wisper.publisher.broadcast bin/rspec spec/models
```

- PaperTrail logs creation:

Enable custom profiling:

```rb
TestProf::EventProf.monitor(PaperTrail::RecordTrail, "paper_trail.record", :record_create)
TestProf::EventProf.monitor(PaperTrail::RecordTrail, "paper_trail.record", :record_destroy)
TestProf::EventProf.monitor(PaperTrail::RecordTrail, "paper_trail.record", :record_update)
```

Run tests:

```sh
EVENT_PROF=paper_trail.record bin/rspec spec/models
```

See [the Sidekiq example](https://evilmartians.com/chronicles/testprof-a-good-doctor-for-slow-ruby-tests#background-jobs) on how to quickly fix such problems using [RSpecStamp](./recipes/rspec_stamp.md).

### Step 3.2. Data generation

Identify the slowest tests based on the amount of time spent in the database or factories (if any):

```sh
# Database interactions
EVENT_PROF=sql.active_record bin/rspec spec/models

# Factories
EVENT_PROF=factory.create bin/rspec spec/models
```

Now, we can narrow our scope further to the top 10 files from the generated reports. If you use factories, use the `factory.create` report.

**TIP:** In RSpec, you can mark the slowest examples with a custom tag automatically using the following command:

```sh
EVENT_PROF=factory.create EVEN_PROF_STAMP=slow:factory bin/rspec spec/models
```

## Step 4. Factories usage

Identify the most used factories among the `slow:factory` tests:

```sh
FPROF=1 bin/rspec --tag slow:factory
```

If you see some factories used much more times than the total number of examples, you deal with _factory cascades_.

Visualize the cascades:

```sh
FPROF=flamegraph bin/rspec --tag slow:factory
```

The visualization should help to identify the factories to be fixed. You find possible solutions in [this post](https://evilmartians.com/chronicles/testprof-2-factory-therapy-for-your-ruby-tests-rspec-minitest).

### Step 4.1. Factory defaults

One option to fix cascades produced by model associations is to use [factory defaults](./recipes/factory_default.md). To estimate the potential impact and identify factories to apply this pattern to, run the following profiler:

```sh
FACTORY_DEFAULT_PROF=1 bin/rspec --tag slow:factory
```

Try adding `create_default` and measure the impact:

```sh
FACTORY_DEFAULT_SUMMARY=1 bin/rspec --tag slow:factory

# More hits — better
FactoryDefault summary: hit=11 miss=3
```

### Step 4.2. Factory fixtures

Back to the `FPROF=1` report, see if you have some records created for every example (typically, `user`, `account`, `team`). Consider replacing them with fixtures using [AnyFixture](./recipes/any_fixture.md).

## Step 5. Reusable setup

It's common to have the same setup shared across multiple examples. You can measure the time spent in `let` / `before` compared to the actual example time using [RSpecDissect](./profilers/rspec_dissect.md):

```sh
RD_PROF=1 bin/rspec
```

Take a look at the slowest groups and try to replace `let`/`let!` with [let_it_be](./recipes/let_it_be.md) and `before` with [before_all](./recipes/before_all.md).

**IMPORTANT:** Knapsack Pro users must be aware that per-example balancing eliminates the positive effect of using `let_it_be` / `before_all`. You must switch to per-file balancing while at the same time keeping your files small—that's how you can maximize the effect of using Test Prof optimizations.

## Conclusion

After applying the steps above to a given group of tests, you should develop the patterns and techniques optimized for your codebase. Then, all you need is to extrapolate them to other groups. Good luck!
