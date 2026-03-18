# TPSProf

@available_since version=1.6.0

TPSProf measures tests-per-second (TPS) for your top-level example groups and helps identify the slowest ones. It can also run in **strict mode** to fail the build when groups fall below a TPS threshold.

Example output:

```sh
[TEST PROF INFO] TPSProf enabled (top-10)

[TEST PROF INFO] Total TPS (tests per second): 12.33

Top 10 slowest suites by TPS (tests per second):

UsersController (./spec/controllers/users_controller_spec.rb:3) – 3.45 TPS (00:05.797 / 20, shared setup time: 00:01.203)
PostsController (./spec/controllers/posts_controller_spec.rb:3) – 5.12 TPS (00:03.906 / 20, shared setup time: 00:00.876)
CommentsController (./spec/controllers/comments_controller_spec.rb:3) – 7.89 TPS (00:01.900 / 15, shared setup time: 00:00.410)
```

The output shows TPS for each group along with total time, number of examples, and shared setup time (time spent outside individual examples, e.g., `before(:all)` hooks).

Groups with the highest _penalty_ are shown first. The penalty is calculated as the time wasted compared to the target TPS (defaults to 30). The idea behind the _penalty_ concept is to identify example groups optimizing which would bring the most time savings to your test suite, i.e., the lowest score is not necessary correspond to the lowest TPS but is affected by the total number of examples in the group. Tune your target TPS to get more accurate results.

## Instructions

TPSProf currently supports RSpec only.

### Profile mode (default)

Use the `TPS_PROF` environment variable to activate:

```sh
# Show top-10 slowest groups (default)
TPS_PROF=1 rspec

# Show top-N slowest groups
TPS_PROF=20 rspec
```

### Strict mode

Strict mode reports groups violating thresholds as non-example errors, making the build fail:

```sh
TPS_PROF=strict rspec
```

In strict mode, configure the thresholds to report violations:

```sh
# Fail groups with more than 50 examples
TPS_PROF=strict TPS_PROF_MAX_EXAMPLES=50 rspec

# Fail groups exceeding 30 seconds
TPS_PROF=strict TPS_PROF_MAX_TIME=30 rspec

# Fail groups with TPS lower than 5
TPS_PROF=strict TPS_PROF_MIN_TPS=5 rspec
```

You can combine multiple thresholds:

```sh
TPS_PROF=strict TPS_PROF_MIN_TPS=5 TPS_PROF_MAX_TIME=30 rspec
```

## Configuration

### Filtering thresholds

Groups are only included in the report if they meet **all** of the following criteria:

| Env var | Default | Description |
|---|---|---|
| `TPS_PROF_MIN_EXAMPLES` | 10 | Minimum number of examples in a group |
| `TPS_PROF_MIN_TIME` | 5 | Minimum total group time (seconds) |
| `TPS_PROF_TARGET_TPS` | 30 | Only groups with TPS below this value are reported |

### Report options

| Env var | Default | Description |
|---|---|---|
| `TPS_PROF` | – | Activates the profiler. Use a number for top-N or `strict` for strict mode |
| `TPS_PROF_COUNT` | 10 | Number of groups to show (overrides the `TPS_PROF` number) |
| `TPS_PROF_MODE` | – | Explicitly set mode (`profile` or `strict`), overrides `TPS_PROF=strict` |

### Strict mode thresholds

| Env var | Default | Description |
|---|---|---|
| `TPS_PROF_MAX_EXAMPLES` | – | Report groups with more examples |
| `TPS_PROF_MAX_TIME` | – | Report groups with total time exceeding this value (seconds) |
| `TPS_PROF_MIN_TPS` | – | Report groups with TPS lower than this value |

### Programmatic configuration

You can also configure TPSProf in your test helper:

```ruby
TestProf::TPSProf.configure do |config|
  config.top_count = 15
  # Profiling thresholds
  config.min_examples_count = 5
  config.min_group_time = 3
  config.min_target_tps = 20
  # Strict mode settings
  config.max_examples_count = 100
  config.max_group_time = 60
  config.min_tps = 5
end
```

### Custom strict handler

You can provide a custom strict handler to implement your own violation logic. The handler receives a `GroupInfo` object with the following attributes: `group`, `location`, `examples_count`, `total_time`, `tps`, and `penalty`. Raise an exception to mark the group as a violation. Here is an example configuration to use different TPS thresholds for different test types:

```ruby
TestProf::TPSProf.configure do |config|
  config.mode = :strict
  config.strict_handler = ->(group_info) {
    if group_info.group.metadata[:type] == :system && group_info.tps < 5
      raise "Group #{group_info.location} is too slow: #{group_info.tps} TPS"
    elsif group_info.tps < 20
      raise "Group #{group_info.location} is too slow: #{group_info.tps} TPS"
    end
  }
end
```

## Ignoring groups and examples

You can exclude specific groups from TPSProf tracking using the `tps_prof: :ignore` metadata:

```ruby
RSpec.describe "SlowButOk", tps_prof: :ignore do
  # ...
end
```
