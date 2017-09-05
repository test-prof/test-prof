# Change log

## 0.3.0

Features:

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