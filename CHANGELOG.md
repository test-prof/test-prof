# Change log

## master (unrealeased)

## 0.12.1 (2020-09-01)

- Minor improvements.

## 0.12.0 (2020-07-17)

- Add state leakage detection for `let_it_be`. ([@pirj][], [@jaimerson][], [@alexvko][])

- Add default let_it_be modifiers configuration. ([@palkan][])

You can configure global modifiers:

```ruby
TestProf::LetItBe.configure do |config|
  # Make refind activated by default
  config.default_modifiers[:refind] = true
end
```

Or for specific contexts via tags:

```ruby
context "with let_it_be reload", let_it_be_modifiers: {reload: true} do
  # examples
end
```

- **Drop Ruby 2.4 support.** ([@palkan][])

- SAMPLE and SAMPLE_GROUP work consistently with seed in RSpec and Minitest. ([@stefkin][])

- Make sure EventProf is not affected by time freezing. ([@palkan][])

  EventProf results now is not affected by `Timecop.freeze` or similar.

  See more in [#181](https://github.com/test-prof/test-prof/issues/181).

- Adds the ability to define stackprof's interval sampling by using `TEST_STACK_PROF_INTERVAL` env variable ([@LynxEyes][])

  Now you can use `$ TEST_STACK_PROF=1 TEST_STACK_PROF_INTERVAL=10000 rspec` to define a custom interval (in microseconds).

## 0.11.3 (2020-02-11)

- Disable `RSpec/AggregateFailures` by default. ([@pirj][])

## 0.11.2 (2020-02-11)

- Fix RuboCop integration regressions. ([@palkan][])

## 0.11.1 (2020-02-10)

- Add `config/` to the gem contents. ([@palkan][])

Fixes RuboCop integration regression from 0.11.0.

## 0.11.0 (2020-02-09)

- Fix `let_it_be` issue when initialized with an array/enumerable or an AR relation. ([@pirj][])

- Improve `RSpec/AggregateExamples` (formerly `RSpec/AggregateFailures`) cop. ([@pirj][])

## 0.10.2 (2020-01-07) 🎄

- Fix Ruby 2.7 deprecations. ([@lostie][])

## 0.10.1 (2019-10-17)

- Fix AnyFixture DSL when using with Rails 6.1+. ([@palkan][])

- Fix loading `let_it_be` without ActiveRecord present. ([@palkan][])

- Fix compatibility of `before_all` with [`isolator`](https://github.com/palkan/isolator) gem to handle correct usages of non-atomic interactions outside DB transactions. ([@Envek][])

- Updates FactoryProf to show the amount of time taken per factory call. ([@tyleriguchi][])

## 0.10.0 (2019-08-19)

- Use RSpec example ID instead of full description for RubyProf/Stackprof report names. ([@palkan][])

For more complex scenarios feel free to use your own report name generator:

```ruby
# for RubyProf
TestProf::RubyProf::Listener.report_name_generator = ->(example) { "..." }
# for Stackprof
TestProf::StackProf::Listener.report_name_generator = ->(example) { "..." }
```

- Support arrays in `let_it_be` with modifiers. ([@palkan][])

```ruby
# Now you can use modifiers with arrays
let_it_be(:posts, reload: true) { create_pair(:post) }
```

- Refactor `let_it_be` modifiers and allow adding custom modifiers. ([@palkan][])

```ruby
TestProf::LetItBe.config.register_modifier :reload do |record, val|
  # ignore when `reload: false`
  next record unless val
  # ignore non-ActiveRecord objects
  next record unless record.is_a?(::ActiveRecord::Base)
  record.reload
end
```

- Print warning when `ActiveRecordSharedConnection` is used in the version of Rails
supporting `lock_threads` (5.1+). ([@palkan][])

## 0.9.0 (2019-05-14)

- Add threshold and custom event support to FactoryDoctor. ([@palkan][])

```sh
$ FDOC=1 FDOC_EVENT="sql.rom" FDOC_THRESHOLD=0.1 rspec
```

- Add Fabrication support to FactoryDoctor. ([@palkan][])

- Add `guard` and `top_level` options to `EventProf::Monitor`. ([@palkan][])

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

- Add global `before_all` hooks. ([@danielwaterworth][], [@palkan][])

Now you can run additional code before and after every `before_all` transaction
begins and rollbacks:

```ruby
TestProf::BeforeAll.configure do |config|
  config.before(:begin) do
    # do something before transaction opens
  end

  config.after(:rollback) do
    # do something after transaction closes
  end
end
```

- Add ability to use `let_it_be` aliases with predefined options. ([@danielwaterworth][])

```ruby
TestProf::LetItBe.configure do |config|
  config.alias_to :let_it_be_with_refind, refind: true
end
```

- Made FactoryProf measure and report on timing ([@danielwaterworth][])

See [changelog](https://github.com/test-prof/test-prof/blob/v0.8.0/CHANGELOG.md) for versions <0.9.0.

[@palkan]: https://github.com/palkan
[@marshall-lee]: https://github.com/marshall-lee
[@danielwestendorf]: https://github.com/danielwestendorf
[@Shkrt]: https://github.com/Shkrt
[@IDolgirev]: https://github.com/IDolgirev
[@desoleary]: https://github.com/desoleary
[@rabotyaga]: https://github.com/rabotyaga
[@Vasfed]: https://github.com/Vasfed
[@szemek]: https://github.com/szemek
[@mkldon]: https://github.com/mkldon
[@dmagro]: https://github.com/dmagro
[@danielwaterworth]: https://github.com/danielwaterworth
[@Envek]: https://github.com/Envek
[@tyleriguchi]: https://github.com/tyleriguchi
[@lostie]: https://github.com/lostie
[@pirj]: https://github.com/pirj
[@LynxEyes]: https://github.com/LynxEyes
[@stefkin]: https://github.com/stefkin
[@jaimerson]: https://github.com/jaimerson
[@alexvko]: https://github.com/alexvko
