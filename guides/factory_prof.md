# FactoryProf

FactoryProf tracks your factories usage statistics, i.e. how often each factory has been used.

Example output:

```sh
[TEST PROF INFO] Factories usage

 total      top-level             name

     8              4             user
     5              3             post
```


It shows both the total number of the factory runs and the number of _top-level_ runs, i.e. not during another factory invocation (e.g. when using associations.)

**NOTE**: FactoryProf only tracks the database-persisted factories. In case of FactoryGirl/FactoryBot these are the factories
provided by using `create` strategy. In case of Fabrication - objects that created using `create` method.

## Instructions

FactoryProf can be used with FactoryGirl/FactoryBot or Fabrication - application can be bundled with both gems at the same time.

To activate FactoryProf use `FPROF` environment variable:

```sh
# Simple profiler
FPROF=1 rspec

# or
FPROF=1 bundle exec rake test
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

![](assets/factory-flame.gif)

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

## Acknowledgements

- Thanks to [Martin Spier](https://github.com/spiermar) for [d3-flame-graph](https://github.com/spiermar/d3-flame-graph)

- Thanks to [Sam Saffron](https://github.com/SamSaffron) for his [flame graphs implementation](https://github.com/SamSaffron/flamegraph).
