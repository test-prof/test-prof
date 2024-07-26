# FactoryProf

FactoryProf tracks your factories usage statistics, i.e. how often each factory has been used.

Example output:

```sh
[TEST PROF INFO] Factories usage

Total: 15285
Total top-level: 10286
Total time: 04:31.222 (out of 07.16.124)
Total uniq factories: 119

   name           total   top-level   total time    time per call      top-level time

   user            6091        2715    115.7671s          0.0426s            50.2517s
   post            2142        2098     93.3152s          0.0444s            92.1915s
   ...
```

It shows both the total number of the factory runs and the number of _top-level_ runs, i.e. not during another factory invocation (e.g. when using associations.)

It also shows the time spent generating records with factories and the amount of time taken per factory call.

**NOTE**: FactoryProf only tracks the database-persisted factories. In case of FactoryGirl/FactoryBot these are the factories provided by using `create` strategy. In case of Fabrication - objects that created using `create` method.

## Instructions

FactoryProf can be used with FactoryGirl/FactoryBot or Fabrication - application can be bundled with both gems at the same time.

To activate FactoryProf use `FPROF` environment variable:

```sh
# Simple profiler
FPROF=1 rspec

# or
FPROF=1 bundle exec rake test
```

### [_Nate Heckler_](https://twitter.com/nateberkopec/status/1389945187766456333) mode

To encourage you to fix your factories as soon as possible, we also have a special _Nate heckler_ mode.

Drop this into your `rails_helper.rb` or `test_helper.rb`:

```ruby
require "test_prof/factory_prof/nate_heckler"
```

And for every test run see the overall factories usage:

```sh
[TEST PROF INFO] Time spent in factories: 04:31.222 (54% of total time)
```

### Variations

You can also add _variations_ (such as traits, overrides) information to reports by providing the `FPROF_VARS=1` environment variable or enabling it in your code:

```ruby
TestProf::FactoryProf.configure do |config|
  config.include_variations = true
end
```

For example:

```sh
$ FPROF=1 FPROF_VARS=1 bin/rails test

...

[TEST PROF INFO] Factories usage

Total: 15285
Total top-level: 10286
Total time: 04:31.222 (out of 07.16.124)
Total uniq factories: 119

   name           total   top-level   total time    time per call      top-level time

   user            6091        2715    115.7671s          0.0426s             50.251s
     -             5243        1989      84.231s          0.0412s             34.321s
     .admin         823         715      15.767s          0.0466s              5.257s
     [name,role]     25          11       7.671s          0.0666s              1.257s
   post            2142        2098      93.315s          0.0444s             92.191s
     _             2130        2086      87.685s          0.0412s             88.191s
     .draft[tags]    12          12       9.315s           0.164s             42.115s
   ...
```

In the example above, `-` indicates a factory without traits or overrides (e.g., `create(:user)`), `.xxx` indicates a trait and `[a,b]` indicates the overrides keys, e.g., `create(:user, :admin)` is an `.admin` variation, while `create(:post, :draft, tags: ["a"])`—`.draft[tags]`

#### Variations limit config

When running FactoryProf, the output may contain a variant that is too long, which will distort the output.

To avoid this and focus on the most important statistics you can specify a variations limit value. Then a special ID (`[...]`) will be shown instead of the variant with the number of traits/overrides exceeding the limit.

To use variations limit parameter set `FPROF_VARIATIONS_LIMIT` environment variable to `N` (where `N` is a limit number):

```sh
FPROF=1 FPROF_VARIATIONS_LIMIT=5 rspec

# or
FPROF=1 FPROF_VARIATIONS_LIMIT=5 bundle exec rake test
```

Or you can set the limit parameter through the `FactoryProf` configuration:

```ruby
TestProf::FactoryProf.configure do |config|
  config.variations_limit = 5
end
```

### Exporting profile results to a JSON file

FactoryProf can save profile results as a JSON file.

To use this feature, set the `FPROF` environment variable to `json`:

```sh
FPROF=json rspec

# or
FPROF=json bundle exec rake test
```

Example output:

```sh
[TEST PROF INFO] Profile results to JSON: tmp/test_prof/test-prof.result.json
```

### Reducing the output

When running FactoryProf, the output may contain a lot of lines for factories that has been used a few times.
To avoid this and focus on the most important statistics you can specify a threshold value. Then you will be shown the factories whose total number exceeds the threshold.

To use threshold option set `FPROF_THRESHOLD` environment variable to `N` (where `N` is a threshold number):

```sh
FPROF=1 FPROF_THRESHOLD=30 rspec

# or
FPROF=1 FPROF_THRESHOLD=30 bundle exec rake test
```

Or you can set the threshold parameter through the `FactoryProf` configuration:

```ruby
TestProf::FactoryProf.configure do |config|
  config.threshold = 30
end
```

## Factory Flamegraph

The most useful feature of FactoryProf is the _FactoryFlame_ report. That's the special interpretation of Brendan Gregg's [flame graphs](http://www.brendangregg.com/flamegraphs.html) which allows you to identify _factory cascades_.

To generate FactoryFlame report set `FPROF` environment variable to `flamegraph`:

```sh
FPROF=flamegraph rspec

# or
FPROF=flamegraph bundle exec rake test
```

That's how a report looks like:

<img alt="TagProf UI" data-origin="/assets/factory-flame.gif" src="/assets/factory-flame.gif">

How to read this?

Every column represents a _factory stack_ or _cascade_, that is a sequence of recursive `#create` method calls. Consider an example:

```ruby
factory :comment do
  answer
  author
end

factory :answer do
  question
  author
end

factory :question do
  author
end

create(:comment) #=> creates 5 records

# And the corresponding stack is:
# [:comment, :answer, :question, :author, :author, :author]
```

The wider column the more often this stack appears.

The `root` cell shows the total number of `create` calls.

## Acknowledgments

- Thanks to [Martin Spier](https://github.com/spiermar) for [d3-flame-graph](https://github.com/spiermar/d3-flame-graph)

- Thanks to [Sam Saffron](https://github.com/SamSaffron) for his [flame graphs implementation](https://github.com/SamSaffron/flamegraph).
