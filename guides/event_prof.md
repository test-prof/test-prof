# EventProf

EventProf collects instrumentation (such as ActiveSupport::Notifications) metrics during your test suite run.

It works very similar to `rspec --profile` but can track arbitrary events.

Example output:

```sh
[TEST PROF INFO] EventProf results for sql.active_record

Total time: 00:00.256
Total events: 1031

Top 5 slowest suites (by time):

AnswersController (./spec/controllers/answers_controller_spec.rb:3) – 00:00.119 (549 / 20)
QuestionsController (./spec/controllers/questions_controller_spec.rb:3) – 00:00.105 (360 / 18)
CommentsController (./spec/controllers/comments_controller_spec.rb:3) – 00:00.032 (122 / 4)

Top 5 slowest tests (by time):

destroys question (./spec/controllers/questions_controller_spec.rb:38) – 00:00.022 (29)
change comments count (./spec/controllers/comments_controller_spec.rb:7) – 00:00.011 (34)
change Votes count (./spec/shared_examples/controllers/voted_examples.rb:23) – 00:00.008 (25)
change Votes count (./spec/shared_examples/controllers/voted_examples.rb:23) – 00:00.008 (32)
fails (./spec/shared_examples/controllers/invalid_examples.rb:3) – 00:00.007 (34)

```

## Instructions

Currently, EventProf supports only ActiveSupport::Notifications and RSpec.

To activate EventProf use `EVENT_PROF` environment variable set to event name:

```sh
# Collect SQL queries stats for every suite and example
EVENT_PROF='sql.active_record' rspec ...
```

See [Rails guides](http://guides.rubyonrails.org/active_support_instrumentation.html)
for the list of available events if you're using Rails.

If you're using [rom-rb](http://rom-rb.org) you might be interested in profiling `'sql.rom'` event.

### Configuration

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

See [event_prof.rb](https://github.com/palkan/test-prof/tree/master/lib/test_prof/event_prof.rb) for all available configuration options and their usage.

## Using with RSpecStamp

EventProf can be used with [RSpec Stamp](https://github.com/palkan/test-prof/tree/master/guides/rspec_stamp.md) to automatically mark _slow_ examples with custom tags. For example:

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
    raise ArgumentError, 'Block is required!' unless block_given?

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
