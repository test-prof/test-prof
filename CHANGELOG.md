# Change log

## master

- Fix bug when using rspec-rails over rspec. ([@desoleary][])

## 0.4.5

- Fix circular require in `lib/factory_doctor/minitest`. ([@palkan][])

## 0.4.4

- [Fixes [#48](https://github.com/palkan/test-prof/issues/48)] Respect RubyProf reports files extensions. ([@palkan][])

## 0.4.3

- [#46](https://github.com/palkan/test-prof/pull/46) Support FactoryBot, which is [former FactoryGirl](https://github.com/thoughtbot/factory_bot/pull/1051),
  while maintaining compatibility with latter. ([@Shkrt][])

## 0.4.2

- Fix bug with multiple `before_all` within one group. ([@palkan][])

## 0.4.1

- [#44](https://github.com/palkan/test-prof/pull/44) Support older versions of RSpec. ([@palkan][])

Support RSpec 3.1.0+ in general.

`let_it_be` supports only RSpec 3.3.0+.

RSpecDissect `let` tracking supports only RSpec 3.3.0+.

- [#38](https://github.com/palkan/test-prof/pull/38) Factory Doctor Minitest integration. ([@IDolgirev][])

It is possible now to use Factory Doctor with Minitest

## 0.4.0

### Features:

- [#29](https://github.com/palkan/test-prof/pull/29) EventProf Minitest integration. ([@IDolgirev][])

It is possible now to use Event Prof with Minitest

- [#30](https://github.com/palkan/test-prof/pull/30) Fabrication support for FactoryProf. ([@Shkrt][])

FactoryProf now also accounts objects created by Fabrication gem (in addition to FactoryGirl)

## 0.3.0

### Features:

- Combine RSpecStamp with FactoryDoctor. ([@palkan][])

Automatically mark _bad_ examples with custom tags.

- [#17](https://github.com/palkan/test-prof/pull/17) Combine RSpecStamp with EventProf and RSpecDissect. ([@palkan][])

It is possible now to automatically mark _slow_ examples and groups with custom tags. For example:

```sh
EVENT_PROF="sql.active_record" EVENT_PROF_STAMP="slow:sql" rspec ...
```

After running the command above the top 5 slowest example groups would be marked with `slow: :sql` tag.

- [#14](https://github.com/palkan/test-prof/pull/14) RSpecDissect profiler. ([@palkan][])

RSpecDissect tracks how much time do you spend in `before` hooks
and memoization helpers (i.e. `let`) in your tests.

- [#13](https://github.com/palkan/test-prof/pull/13) RSpec `let_it_be` method. ([@palkan][])

Just like `let`, but persist the result for the whole group (i.e. `let` + `before_all`).

### Improvements:

- Add ability to specify RubyProf report through `TEST_RUBY_PROF` env variable. ([@palkan][])

- Add ability to specify StackProf raw mode through `TEST_STACK_PROF` env variable. ([@palkan][])

### Changes

- Use RubyProf `FlatPrinter` by default (was `CallStackPrinter`). ([@palkan][])

## 0.2.5

- [#16](https://github.com/palkan/test-prof/pull/16) Support Ruby >= 2.2.0 (was >= 2.3.0). ([@palkan][])

## 0.2.4

- EventProf: Fix regression bug with examples profiling. ([@palkan][])

There was a bug when an event occurs before the example has started (e.g. in `before(:context)` hook).

## 0.2.3

- Minor improvements. ([@palkan][])

## 0.2.2

- Fix time calculation when Time class is monkey-patched. ([@palkan][])

Add `TestProf.now` method which is just a copy of original `Time.now` and
use it everywhere.

Fixes [#10](https://github.com/palkan/test-prof/issues/10).

## 0.2.1

- Detect `RSpec` by checking the presence of `RSpec::Core`. ([@palkan][])

Fixes [#8](https://github.com/palkan/test-prof/issues/8).

## 0.2.0

- Ensure output directory exists. ([@danielwestendorf][])

**Change default output dir** to "tmp/test_prof".

Rename `#artefact_path` to `#artifact_path` to be more US-like

Ensure output dir exists in `#artifact_path` method.

- FactoryDoctor: print success message when no bad examples found. ([@palkan][])

## 0.1.1

- AnyFixture: clean tables in reverse order to not fail when foreign keys exist. ([@marshall-lee][])

## 0.1.0

- Initial version. ([@palkan][])

[@palkan]: https://github.com/palkan
[@marshall-lee]: https://github.com/marshall-lee
[@danielwestendorf]: https://github.com/danielwestendorf
[@Shkrt]: https://github.com/Shkrt
[@IDolgirev]: https://github.com/IDolgirev
[@desoleary]: https://github.com/desoleary
