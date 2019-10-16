# Change log

## master (unreleased)

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

## 0.8.0 (2019-04-12) 🚀

- **Ruby 2.4+ is requiered** ([@palkan][])

- **RSpec 3.5+ is requiered for RSpec features** ([@palkan][])

- Make `before_all` compatible with [`isolator`](https://github.com/palkan/isolator). ([@palkan][])

- Add `with_logging` and `with_ar_logging` helpers to logging recipe. ([@palkan][])

- Make `before_all` for Active Record `lock_thread` aware. ([@palkan][])

  `before_all` can went crazy if you open multiple connections within it
  (since it tracks the number of open transactions).
  Rails 5+ `lock_thread` feature only locks the connection thread in
  `before`/`setup` hook thus making it possible to have multiple connections/transactions
  in `before_all` (e.g. performing jobs with Active Job async adapter).

## 0.7.5 (2019-02-22)

- Make `let_it_be` and `before_all` work with `include_context`. ([@palkan][])

  Fixes [#117](https://github.com/palkan/test-prof/issues/117)

## 0.7.4 (2019-02-16)

- Add JSON report support for StackProf. ([@palkan][])

- Add ability to specify report/artifact name suffixes. ([@palkan][])

## 0.7.3 (2018-11-07)

- Add a header with the general information on factories usage [#99](https://github.com/palkan/test-prof/issues/99) ([@szemek][])

- Improve test sampling.([@mkldon][])

  ```bash
  $ SAMPLE=10 rake test # runs 10 random test examples
  $ SAMPLE_GROUPS=10 rake test # runs 10 random example groups
  ```

- Extend Event Prof formatter to include the absolute run time and the percentage of the event tim [#100](https://github.com/palkan/test-prof/issues/100) ([@dmagro][])

## 0.7.2 (2018-10-08)

- Add `RSpec/AggregateFailures` support for non-regular 'its' examples. ([@broels][])

## 0.7.1 (2018-08-20)

- Add ability to ignore connection configurations in shared connection.([@palkan][])

  Example:

  ```ruby
  # Do not use shared connection for sqlite db
  TestProf::ActiveRecordSharedConnection.ignore { |config| config[:adapter] == "sqlite3" }
  ```

## 0.7.0 (2018-08-12)

- **Ruby 2.3+ is required**. ([@palkan][])

  Ruby 2.2 EOL was on 2018-03-31.

- Upgrade RubyProf integration to `ruby-prof >= 0.17`. ([@palkan][])

  Use `exclude_common_methods!` instead of the deprecated `eliminate_methods!`.

  Add RSpec specific exclusions.

  Add ability to specify custom exclusions through `config.custom_exclusions`, e.g.:

  ```ruby
  TestProf::RubyProf.configure do |config|
    config.custom_exclusions = {User => %i[save save!]}
  end
  ```

## 0.6.0 (2018-06-29)

### Features

- Add `EventProf.monitor` to instrument arbitrary methods. ([@palkan][])

  Add custom instrumetation easily:

  ```ruby
  class Work
    def do
      # ...
    end
  end

  # Instrument Work#do calls with "my.work" event
  TestProf::EventProf.monitor(Work, "my.work", :do)
  ```

[📝 Docs](https://test-prof.evilmartians.io/#/event_prof?id=profile-arbitrary-methods)

- Adapterize `before_all`. ([@palkan][])

  Now it's possible to write your own adapter for `before_all` to manage transactions.

[📝 Docs](https://test-prof.evilmartians.io/#/before_all?id=database-adapters)

- Add `before_all` for Minitest. ([@palkan][])

[📝 Docs](https://test-prof.evilmartians.io/#/before_all?id=minitest-experimental)

### Fixes & Improvements

- Show top `let` declarations per example group in RSpecDissect profiler. ([@palkan][])

  The output now includes the following information:

  ```
  Top 5 slowest suites (by `let` time):

  FunnelsController (./spec/controllers/funnels_controller_spec.rb:3) – 00:38.532 of 00:43.649 (133)
  ↳ user – 3
  ↳ funnel – 2
  ApplicantsController (./spec/controllers/applicants_controller_spec.rb:3) – 00:33.252 of 00:41.407 (222)
  ↳ user – 10
  ↳ funnel – 5
  ```

  Enabled by default. Disable it with:

  ```ruby
  TestProf::RSpecDissect.configure do |config|
    config.let_stats_enabled = false
  end
  ```

- [Fix [#80](https://github.com/palkan/test-prof/issues/80)] Added ability to preserve traits. ([@Vasfed][])

  Disabled by default for compatibility. Enable globally by `FactoryDefault.preserve_traits = true` or for single `create_default`: `create_default(:user, preserve_traits: true)`

  When enabled - default object will be used only when there's no [traits](https://github.com/thoughtbot/factory_bot/blob/master/GETTING_STARTED.md#traits) in association.

- Add ability to run only `let` or `before` profiler with RSpecDissect. ([@palkan][])

- Collect _raw_ data with StackProf by default. ([@palkan][])

- Refactor `:with_clean_fixture` to clean data once per group. ([@palkan][])

- [Fix [#75](https://github.com/palkan/test-prof/issues/75)] Fix `RSpec/Aggregate` failures with non-regular examples. ([@palkan][])

  Do not take into account `xit`, `pending`, `its`, etc. examples,
  only consider regular `it`, `specify`, `scenario`, `example`.

## 0.5.0 (2018-04-25)

### Features

- Add events support to TagProf. ([@palkan][])

  Example usage:

  ```sh
  TAG_PROF=type TAG_PROF_EVENT=sql.active_record rspec
  ```

  [📝 Docs](https://test-prof.evilmartians.io/#/tag_prof?id=profiling-events)

- Add logging helpers for Rails. ([@palkan][])

  Enable verbose logging globally:

  ```sh
  LOG=all rspec
  ```

  Or per example (group):

  ```ruby
  it "does smth weird", :log do
    # ...
  end
  ```

  [📝 Docs](https://test-prof.evilmartians.io/#/logging)

- Add HTML report for `TagProf`. ([@palkan][])

  Generate HTML report by setting `TAG_PROF_FORMAT` to `html`.

- Add ability to track multiple events at the same time with `EventProf`. ([@palkan][])

- Add `AnyFixture` DSL. ([@palkan][])

  Example:

  ```ruby
  # Enable DSL
  using TestProf::AnyFixture::DSL

  # and then you can use `fixture` method (which is just an alias for `TestProf::AnyFixture.register`)
  before(:all) { fixture(:account) }

  # You can also use it to fetch the record (instead of storing it in instance variable)
  let(:account) { fixture(:account) }
  ```

  [📝 Docs](https://test-prof.evilmartians.io/#/any_fixture?id=dsl)

- Add `AnyFixture` usage report. ([@palkan][])

  Enable `AnyFixture` usage reporting with `ANYFIXTURE_REPORTING=1` or with:

  ```ruby
  TestProf::AnyFixture.reporting_enabled = true
  ```

  [📝 Docs](https://test-prof.evilmartians.io/#/any_fixture?id=usage-report)

- Add `ActiveRecordSharedConnection` recipe. ([@palkan][])

  Force ActiveRecord to use the same connection between threads (to avoid database cleaning in browser tests).

  [📝 Docs](https://test-prof.evilmartians.io/#/active_record_shared_connection)

- [#70](https://github.com/palkan/test-prof/pull/70) Add `FactoryAllStub` recipe. ([@palkan][])

  [📝 Docs](https://test-prof.evilmartians.io/#/factory_all_stub)

- Add `ActiveRecordRefind` refinement. ([@palkan][])

  [📝 Docs](https://test-prof.evilmartians.io/#/any_fixture?id=activerecordrefind)

### Fixes & Improvements

- **Brand new documentatation website: https://test-prof.evilmartians.io/**

- Disable referential integrity when cleaning AnyFixture. ([@palkan][])


## 0.4.9 (2018-03-20)

- [Fix [#64](https://github.com/palkan/test-prof/issues/64)] Fix dependencies requiring for FactoryDefault. ([@palkan][])

- [Fix [#60](https://github.com/palkan/test-prof/issues/60)] Fix RSpecDissect reporter hooks. ([@palkan][])

  Consider only `example_failed` and `example_passed` to ensure that the `run_time`
  is available.

## 0.4.8 (2018-01-17)

- Add `minitest` 5.11 support. ([@palkan][])

- Fix `spring` detection. ([@palkan][])

  Some `spring`-related gems do not check whether Spring is running and load
  Spring modules. Thus we have `Spring` defined (and even `Spring.after_fork` defined) but no-op.

  Now we require that `Spring::Applcation` is defined in order to rely on Spring.

  Possibly fixes [#47](https://github.com/palkan/test-prof/issues/47).

## 0.4.7 (2017-12-25)

- [#57](https://github.com/palkan/test-prof/pull/57) Fix RubyProf Printers Support ([@rabotyaga][])

## 0.4.6 (2017-12-17)

- Upgrade RSpec/AggregateFailures to RuboCop 0.52.0. ([@palkan][])

  RuboCop < 0.51.0 is not supported anymore.

- [Fixes [#49](https://github.com/palkan/test-prof/issues/49)] Correctly detect RSpec version in `let_it_be`. ([@desoleary][])

## 0.4.5 (2017-12-09)

- Fix circular require in `lib/factory_doctor/minitest`. ([@palkan][])

## 0.4.4 (2017-11-08)

- [Fixes [#48](https://github.com/palkan/test-prof/issues/48)] Respect RubyProf reports files extensions. ([@palkan][])

## 0.4.3 (2017-10-26)

- [#46](https://github.com/palkan/test-prof/pull/46) Support FactoryBot, which is [former FactoryGirl](https://github.com/thoughtbot/factory_bot/pull/1051),
  while maintaining compatibility with latter. ([@Shkrt][])

## 0.4.2 (2017-10-23)

- Fix bug with multiple `before_all` within one group. ([@palkan][])

## 0.4.1 (2017-10-18)

- [#44](https://github.com/palkan/test-prof/pull/44) Support older versions of RSpec. ([@palkan][])

  Support RSpec 3.1.0+ in general.

  `let_it_be` supports only RSpec 3.3.0+.

  RSpecDissect `let` tracking supports only RSpec 3.3.0+.

- [#38](https://github.com/palkan/test-prof/pull/38) Factory Doctor Minitest integration. ([@IDolgirev][])

  It is possible now to use Factory Doctor with Minitest

## 0.4.0 (2017-10-03)

### Features:

- [#29](https://github.com/palkan/test-prof/pull/29) EventProf Minitest integration. ([@IDolgirev][])

  It is possible now to use Event Prof with Minitest

- [#30](https://github.com/palkan/test-prof/pull/30) Fabrication support for FactoryProf. ([@Shkrt][])

FactoryProf now also accounts objects created by Fabrication gem (in addition to FactoryGirl)

## 0.3.0 (2017-09-21)

### Features:

- Combine RSpecStamp with FactoryDoctor. ([@palkan][])

  Automatically mark _bad_ examples with custom tags.

- [#17](https://github.com/palkan/test-prof/pull/17) Combine RSpecStamp with EventProf and RSpecDissect. ([@palkan][])

  It is possible now to automatically mark _slow_ examples and groups with custom tags. For example:

  ```sh
  $ EVENT_PROF="sql.active_record" EVENT_PROF_STAMP="slow:sql" rspec ...
  ```

  After running the command above the top 5 slowest example groups would be marked with `slow: :sql` tag.

- [#14](https://github.com/palkan/test-prof/pull/14) RSpecDissect profiler. ([@palkan][])

  RSpecDissect tracks how much time do you spend in `before` hooks and memoization helpers (i.e. `let`) in your tests.

- [#13](https://github.com/palkan/test-prof/pull/13) RSpec `let_it_be` method. ([@palkan][])

  Just like `let`, but persist the result for the whole group (i.e. `let` + `before_all`).

### Improvements:

- Add ability to specify RubyProf report through `TEST_RUBY_PROF` env variable. ([@palkan][])

- Add ability to specify StackProf raw mode through `TEST_STACK_PROF` env variable. ([@palkan][])

### Changes

- Use RubyProf `FlatPrinter` by default (was `CallStackPrinter`). ([@palkan][])

## 0.2.5 (2017-08-30)

- [#16](https://github.com/palkan/test-prof/pull/16) Support Ruby >= 2.2.0 (was >= 2.3.0). ([@palkan][])

## 0.2.4 (2017-08-29)

- EventProf: Fix regression bug with examples profiling. ([@palkan][])

  There was a bug when an event occurs before the example has started (e.g. in `before(:context)` hook).

## 0.2.3 (2017-08-28)

- Minor improvements. ([@palkan][])

## 0.2.2 (2017-08-23)

- Fix time calculation when Time class is monkey-patched. ([@palkan][])

  Add `TestProf.now` method which is just a copy of original `Time.now` and use it everywhere.

Fixes [#10](https://github.com/palkan/test-prof/issues/10).

## 0.2.1 (2017-08-19)

- Detect `RSpec` by checking the presence of `RSpec::Core`. ([@palkan][])

  Fixes [#8](https://github.com/palkan/test-prof/issues/8).

## 0.2.0 (2017-08-18)

- Ensure output directory exists. ([@danielwestendorf][])

  **Change default output dir** to "tmp/test_prof".

  Rename `#artefact_path` to `#artifact_path` to be more US-like

  Ensure output dir exists in `#artifact_path` method.

- FactoryDoctor: print success message when no bad examples found. ([@palkan][])

## 0.1.1 (2017-08-17)

- AnyFixture: clean tables in reverse order to not fail when foreign keys exist. ([@marshall-lee][])

## 0.1.0 (2017-08-15)

- Initial version. ([@palkan][])

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
