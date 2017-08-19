# Change log

## master

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