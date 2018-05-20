# Getting Started

## Installation

Add `test-prof` gem to your application:

```ruby
group :test do
  gem 'test-prof'
end
```

That's it! Now you can use TestProf [profilers](/#profilers).

## Configuration

TestProf global configuration is used by most of the profilers:

```ruby
TestProf.configure do |config|
  # the directory to put artifacts (reports) in ("tmp/test_prof" by default)
  config.output_dir = "tmp/test_prof"

  # use unique filenames for reports (by simply appending current timestamp)
  config.timestamps = true

  # color output
  config.color = true
end
```
