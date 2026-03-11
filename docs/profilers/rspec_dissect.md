# RSpecDissect

Do you know how much time you spend in `before` hooks? Or in memoization helpers such as `let`? Usually, the most of the whole test suite time.

_RSpecDissect_ provides this kind of information and also shows you the example groups with the highest **setup time**. The main purpose of RSpecDissect is to identify these slow groups and refactor them using [`before_all`](../recipes/before_all.md) or [`let_it_be`](../recipes/let_it_be.md) recipes.

Example output:

```sh
[TEST PROF INFO] RSpecDissect report

Total time: 25:14.870
Total setup time: 14:36.482

Top 5 slowest suites setup time:

Webhooks::DispatchTransition (./spec/services/webhooks/dispatch_transition_spec.rb:3) – 00:29.895 of 00:33.706 / 327 (before: 00:25.346, before let: 00:19.389, lazy let: 00:04.543)
  ↳ user – 00:09.323 (327)
  ↳ funnel – 00:06.231 (122)
  ↳ account – 00:04.360 (91)

FunnelsController (./spec/controllers/funnels_controller_spec.rb:3) – 00:22.117 of 00:43.649 / 133 (before: 00:22.117, before let: 00:18.695, lazy let: 00:00.000)
  ↳ user – 00:09.323 (327)
  ↳ funnel – 00:06.231 (122)
...
```

The **setup time** includes the time spent in `before(:each)` hooks and lazy `let` definitions (except `subject`—it's often used to define the action under test, and, thus, shouldn't be considered a part of the setup phase).

As you can see, the profiler also provides an information about the most time consuming `let` definitions.

## Instructions

RSpecDissect can only be used with RSpec (which is clear from the name).

To activate RSpecDissect use `RD_PROF` environment variable:

```sh
RD_PROF=1 rspec ...
```

You can also specify the number of top slow groups through `RD_PROF_TOP` variable:

```sh
RD_PROF=1 RD_PROF_TOP=10 rspec ...
```

You can also specify the number of top `let` declarations to print through `RD_PROF_LET_TOP=10` env var.

## Using with RSpecStamp

RSpecDissect can be used with [RSpec Stamp](../recipes/rspec_stamp.md) to automatically mark _slow_ examples with custom tags. For example:

```sh
RD_PROF=1 RD_PROF_STAMP="slow" rspec ...
```

After running the command above the slowest example groups would be marked with the `:slow` tag.
