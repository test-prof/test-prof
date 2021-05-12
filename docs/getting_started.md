# Getting Started

## Installation

Add `test-prof` gem to your application:

```ruby
group :test do
  gem "test-prof", "~> 1.0"
end
```

That's it! Now you can use TestProf [profilers](/#profilers).

## Configuration

TestProf global configuration is used by most of the profilers:

```ruby
TestProf.configure do |config|
  # the directory to put artifacts (reports) in ('tmp/test_prof' by default)
  config.output_dir = "tmp/test_prof"

  # use unique filenames for reports (by simply appending current timestamp)
  config.timestamps = true

  # color output
  config.color = true

  # where to write logs (defaults)
  config.output = $stdout

  # alternatively, you can specify a custom logger instance
  config.logger = MyLogger.new
end
```

You can also dynamically add artifacts/reports suffixes via `TEST_PROF_REPORT` env variable.
It is useful if you're not using timestamps and want to generate multiple reports with different setups and compare them.

For example, let's compare tests load time with and without `bootsnap` using [`stackprof`](./profilers/stack_prof.md):

```sh
# Generate first report using `-with-bootsnap` suffix
$ TEST_STACK_PROF=boot TEST_PROF_REPORT=with-bootsnap bundle exec rake
$ #=> StackProf report generated: tmp/test_prof/stack-prof-report-wall-raw-boot-with-bootsnap.dump

# Assume that you disabled bootsnap and want to generate a new report
$ TEST_STACK_PROF=boot TEST_PROF_REPORT=no-bootsnap bundle exec rake
$ #=> StackProf report generated: tmp/test_prof/stack-prof-report-wall-raw-boot-no-bootsnap.dump
```

Now you have two stackprof reports with clear names!
