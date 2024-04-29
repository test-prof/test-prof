# TagProf

TagProf is a simple profiler which collects examples statistics grouped by a provided tag value.

That's pretty useful in conjunction with `rspec-rails` built-in feature – `infer_spec_type_from_file_location!` – which automatically adds `type` to examples metadata.

Example output:

```sh
[TEST PROF INFO] TagProf report for type

       type          time   total  %total   %time           avg

    request     00:04.808      42   33.87   54.70     00:00.114
 controller     00:02.855      42   33.87   32.48     00:00.067
      model     00:01.127      40   32.26   12.82     00:00.028
```

It shows both the total number of examples in each group and the total time spent (as long as percentages and average values).

You can also generate an interactive HTML report:

```sh
TAG_PROF=type TAG_PROF_FORMAT=html bundle exec rspec
```

That's how a report looks like:

![TagProf UI](/assets/tag-prof.gif)

## Instructions

TagProf can be used with both RSpec and Minitest (limited support, see  below).

To activate TagProf use `TAG_PROF` environment variable:

With Rspec:

```sh
# Group by type
TAG_PROF=type rspec
```

With Minitest:

```sh
# using pure ruby
TAG_PROF=type ruby

# using Rails built-in task
TAG_PROF=type bin/rails test
```

NB: if another value than "type" is used for TAG_PROF environment variable it will be ignored silently in both Minitest and RSpec.

### Usage specificity with Minitest

Minitest does not support the usage of tags by default. TagProf therefore groups statistics by direct subdirectories of the root test directory. It assumes root test directory is named either `spec` or `test`.

When no root test directory can be found the test statistics will not be grouped with other tests. They will be displayed per test with a significant warning message in the report.

Example:

```sh
[TEST PROF INFO] TagProf report for type

       type          time   sql.active_record  total  %total   %time           avg

__unknown__     00:04.808           00:01.402     42   33.87   54.70     00:00.114
 controller     00:02.855           00:00.921     42   33.87   32.48     00:00.067
      model     00:01.127           00:00.446     40   32.26   12.82     00:00.028
```

## Profiling events

You can combine TagProf with [EventProf](./event_prof.md) to track not only the total time spent but also the time spent for the specified activities (through events):

```
TAG_PROF=type TAG_PROF_EVENT=sql.active_record rspec
```

Example output:

```sh
[TEST PROF INFO] TagProf report for type

       type          time   sql.active_record  total  %total   %time           avg

    request     00:04.808           00:01.402     42   33.87   54.70     00:00.114
 controller     00:02.855           00:00.921     42   33.87   32.48     00:00.067
      model     00:01.127           00:00.446     40   32.26   12.82     00:00.028
```

Multiple events are also supported (comma-separated).

## Pro-Tip: More Types

By default, RSpec only infers types for default Rails app entities (such as controllers, models, mailers, etc.).
Modern Rails applications typically contain other abstractions too (e.g. services, forms, presenters, etc.), but RSpec is not aware of them and doesn't add any metadata.

That's the quick workaround:

```ruby
RSpec.configure do |config|
  # ...
  config.define_derived_metadata(file_path: %r{/spec/}) do |metadata|
    # do not overwrite type if it's already set
    next if metadata.key?(:type)

    match = metadata[:location].match(%r{/spec/([^/]+)/})
    metadata[:type] = match[1].singularize.to_sym
  end
end
```
