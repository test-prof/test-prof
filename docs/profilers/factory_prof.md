# FactoryProf

FactoryProf tracks your factories usage statistics, i.e. how often each factory has been used.

Example output:

```sh
[TEST PROF INFO] Factories usage

Total: 15285
Total top-level: 10286
Total time: 04:31.222 (out of 07.16.124)
Total uniq factories: 119

 total   top-level   total time    time per call      top-level time            name
  6091        2715    115.7671s          0.0426s            50.2517s            user
  2142        2098     93.3152s          0.0444s            92.1915s            post
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

### Exporting profile results to a JSON file

FactoryProf can save profile results as a JSON file.

To use this feature, set the `FPROF` environment variable to `json`:

```sh
FPROF=json rspec

# or
FPROF=json bundle exec rake test
```

Example output:

```
[TEST PROF INFO] Profile results to JSON: tmp/test_prof/test-prof.result.json
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

![](/assets/factory-flame.gif)

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
