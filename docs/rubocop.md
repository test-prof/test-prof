# Custom RuboCop Cops

TestProf comes with the [RuboCop](https://github.com/bbatsov/rubocop) cops that help you write more performant tests.

To enable them, require `test_prof/rubocop` in your RuboCop configuration:

```yml
# .rubocop.yml
require:
 - 'test_prof/rubocop'
```

To configure cops to your needs:

```yml
RSpec/AggregateExamples:
  AddAggregateFailuresMetadata: false
```

Or you can just require it dynamically:

```sh
bundle exec rubocop -r 'test_prof/rubocop' --only RSpec/AggregateExamples
```

## RSpec/AggregateExamples

This cop encourages you to use one of the greatest features of the recent RSpec – aggregating failures within an example.

Instead of writing one example per assertion, you can group _independent_ assertions together, thus running all setup hooks only once.
That can dramatically increase your performance (by reducing the total number of examples).

Consider an example:

```ruby
# bad
it { is_expected.to be_success }
it { is_expected.to have_header("X-TOTAL-PAGES", 10) }
it { is_expected.to have_header("X-NEXT-PAGE", 2) }
its(:status) { is_expected.to eq(200) }

# good
it "returns the second page", :aggregate_failures do
  is_expected.to be_success
  is_expected.to have_header("X-TOTAL-PAGES", 10)
  is_expected.to have_header("X-NEXT-PAGE", 2)
  expect(subject.status).to eq(200)
end
```

Auto-correction will typically add `:aggregate_failures` to examples, but if your project enables it globally, or selectively by e.g. deriving metadata from file location, you may opt-out of adding it using `AddAggregateFailuresMetadata` config option.

This cop supports auto-correct feature, so you can automatically refactor you legacy tests!

**NOTE**: `its` examples shown here have been deprecated as of RSpec 3, but users of the [rspec-its gem](https://github.com/rspec/rspec-its) can leverage this cop to cut out that dependency.

**NOTE**: auto-correction of examples using block matchers, such as `change` is deliberately not supported.
