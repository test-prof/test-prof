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

**NOTE**: FactoryProf only tracks the usage of `create` strategy.

## Instructions

FactoryProf can only be used with FactoryGirl.

To activate FactoryProf use `FPROF` environment variable:

```sh
# Simple profiler
FPROF=1 rspec

# or 
FPROF=1 bundle exec rake test
```

## Factory Flamegraph

TBD