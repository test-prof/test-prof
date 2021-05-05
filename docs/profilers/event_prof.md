# EventProf

EventProf collects instrumentation (such as ActiveSupport::Notifications) metrics during your test suite run.

It works very similar to `rspec --profile` but can track arbitrary events.

Example output:

```sh
[TEST PROF INFO] EventProf results for sql.active_record

Total time: 00:00.256 of 00:00.512 (50.00%)
Total events: 1031

Top 5 slowest suites (by time):

AnswersController (./spec/controllers/answers_controller_spec.rb:3) – 00:00.119 (549 / 20) of 00:00.200 (59.50%)
QuestionsController (./spec/controllers/questions_controller_spec.rb:3) – 00:00.105 (360 / 18) of 00:00.125 (84.00%)
CommentsController (./spec/controllers/comments_controller_spec.rb:3) – 00:00.032 (122 / 4) of 00:00.064 (50.00%)

Top 5 slowest tests (by time):

destroys question (./spec/controllers/questions_controller_spec.rb:38) – 00:00.022 (29) of 00:00.064 (34.38%)
change comments count (./spec/controllers/comments_controller_spec.rb:7) – 00:00.011 (34) of 00:00.022 (50.00%)
change Votes count (./spec/shared_examples/controllers/voted_examples.rb:23) – 00:00.008 (25) of 00:00.022 (36.36%)
change Votes count (./spec/shared_examples/controllers/voted_examples.rb:23) – 00:00.008 (32) of 00:00.035 (22.86%)
fails (./spec/shared_examples/controllers/invalid_examples.rb:3) – 00:00.007 (34) of 00:00.014 (50.00%)

```

## Instructions

Currently, EventProf supports only ActiveSupport::Notifications

To activate EventProf with:

### RSpec

Use `EVENT_PROF` environment variable set to event name:

```sh
# Collect SQL queries stats for every suite and example
EVENT_PROF='sql.active_record' rspec ...
```

You can track multiple events simultaneously:

```sh
EVENT_PROF='sql.active_record,perform.active_job' rspec ...
```

### Minitest

Use `EVENT_PROF` environment variable set to event name:

```sh
# Collect SQL queries stats for every suite and example
EVENT_PROF='sql.active_record' rake test
```

or use CLI options as well:

```sh
# Run a specific file using CLI option
ruby test/my_super_test.rb --event-prof=sql.active_record

# Show the list of possible options:
ruby test/my_super_test.rb --help
```

### Using with Minitest::Reporters

If you're using `Minitest::Reporters` in your project you have to explicitly declare it
in your test helper file:

```sh
require 'minitest/reporters'
Minitest::Reporters.use! [YOUR_FAVORITE_REPORTERS]
```

#### NOTICE

When you have `minitest-reporters` installed as a gem but not declared in your `Gemfile`
make sure to always prepend your test run command with `bundle exec` (but we sure that you always do it).
Otherwise, you'll get an error caused by Minitest plugin system, which scans all the entries in the
`$LOAD_PATH` for any `minitest/*_plugin.rb`, thus initialization of `minitest-reporters` plugin which is
available in that case doesn't happens correctly.

See [Rails guides](http://guides.rubyonrails.org/active_support_instrumentation.html)
for the list of available events if you're using Rails.

If you're using [rom-rb](http://rom-rb.org) you might be interested in profiling `'sql.rom'` event.

## Configuration

By default, EventProf collects information only about top-level groups (aka suites),
but you can also profile individual examples. Just set the configuration option:

```ruby
TestProf::EventProf.configure do |config|
  config.per_example = true
end
```

Or provide the `EVENT_PROF_EXAMPLES=1` env variable.

Another useful configuration parameter – `rank_by`. It's responsible for sorting stats –
either by the time spent in the event or by the number of occurrences:

```sh
EVENT_PROF_RANK=count EVENT_PROF='instantiation.active_record' be rspec
```

See [event_prof.rb](https://github.com/test-prof/test-prof/tree/master/lib/test_prof/event_prof.rb) for all available configuration options and their usage.

## Using with RSpecStamp

EventProf can be used with [RSpec Stamp](../recipes/rspec_stamp.md) to automatically mark _slow_ examples with custom tags. For example:

```sh
EVENT_PROF="sql.active_record" EVENT_PROF_STAMP="slow:sql" rspec ...
```

After running the command above the slowest example groups (and examples if configured) would be marked with the `slow: :sql` tag.

## Custom Instrumentation

To use EventProf with your instrumentation engine just complete the two following steps:

- Add a wrapper for your instrumentation:

```ruby
# Wrapper over your instrumentation
module MyEventsWrapper
  # Should contain the only one method
  def self.subscribe(event)
    raise ArgumentError, "Block is required!" unless block_given?

    ::MyEvents.subscribe(event) do |start, finish, *|
      yield (finish - start)
    end
  end
end
```

- Set instrumenter in the config:

```ruby
TestProf::EventProf.configure do |config|
  config.instrumenter = MyEventsWrapper
end
```

## Custom Events

### `"factory.create"`

FactoryGirl provides its own instrumentation ('factory_girl.run_factory'); but there is a caveat – it fires an event every time a factory is used, even when we use factory for nested associations. Thus it's not possible to calculate the total time spent in factories due to the double calculation.

EventProf comes with a little patch for FactoryGirl which provides instrumentation only for top-level `FactoryGirl.create` calls. It is loaded automatically if you use `"factory.create"` event:

```sh
EVENT_PROF=factory.create bundle exec rspec
```

Also supports Fabrication (tracks implicit and explicit `Fabricate.create` calls).

### `"sidekiq.jobs"`

Collects statistics about Sidekiq jobs that have been run inline:

```sh
EVENT_PROF=sidekiq.jobs bundle exec rspec
```

**NOTE**: automatically sets `rank_by` to `count` ('cause it doesn't make sense to collect the information about time spent – see below).

### `"sidekiq.inline"`

Collects statistics about Sidekiq jobs that have been run inline (excluding nested jobs):

```sh
EVENT_PROF=sidekiq.inline bundle exec rspec
```

Use this event to profile the time spent running Sidekiq jobs.

## Profile arbitrary methods

You can also add your custom events to profile specific methods (for example, after figuring out some hot calls with [RubyProf](./ruby_prof.md) or [StackProf](./stack_prof.md)).

For example, having a class doing some heavy work:

```ruby
class Work
  def do_smth(*args)
    # do something
  end
end
```

You can profile it by adding a _monitor_:

```ruby
# provide a class, event name and methods to monitor
TestProf::EventProf.monitor(Work, "my.work", :do_smth)
```

And then run EventProf as usual:

```sh
EVENT_PROF=my.work bundle exec rake test
```

You can also provide additional options:

- `top_level: true | false` (defaults to `false`): defines whether you want to take into account only top-level invocations and ignore nested triggers of this event (that's how "factory.create" is [implemented](https://github.com/test-prof/test-prof/blob/master/lib/test_prof/event_prof/custom_events/factory_create.rb))
- `guard: Proc` (defaults to `nil`): provide a Proc which could prevent from triggering an event: the method is instrumented only if `guard` returns `true`; `guard` is executed using `instance_exec` and the method arguments are passed to it.

For example:

```ruby
TestProf::EventProf.monitor(
  Sidekiq::Client,
  "sidekiq.inline",
  :raw_push,
  top_level: true,
  guard: ->(*) { Sidekiq::Testing.inline? }
)
```

You can add monitors _on demand_ (i.e. only when you want to track the specified event) by wrapping
the code in `TestProf::EventProf::CustomEvents.register` method:

```ruby
TestProf::EventProf::CustomEvents.register("my.work") do
  TestProf::EventProf.monitor(Work, "my.work", :do_smth)
end

# Then call `activate_all` with the provided event
TestProf::EventProf::CustomEvents.activate_all(TestProf::EventProf.config.event)
```

The block is evaluated only if the specified event is enabled with EventProf.
