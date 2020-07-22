# RSpecDissect

Do you know how much time you spend in `before` hooks? Or in memoization helpers such as `let`? Usually, the most of the whole test suite time.

_RSpecDissect_ provides this kind of information and also shows you the worst example groups. The main purpose of RSpecDissect is to identify these slow groups and refactor them using [`before_all`](../recipes/before_all.md) or [`let_it_be`](../recipes/let_it_be.md) recipes.

Example output:

```sh
[TEST PROF INFO] RSpecDissect enabled

Total time: 25:14.870
Total `before(:each)` time: 14:36.482
Total `let` time: 19:20.259

Top 5 slowest suites (by `before(:each)` time):

Webhooks::DispatchTransition (./spec/services/webhooks/dispatch_transition_spec.rb:3) – 00:29.895 of 00:33.706 (327)
FunnelsController (./spec/controllers/funnels_controller_spec.rb:3) – 00:22.117 of 00:43.649 (133)
ApplicantsController (./spec/controllers/applicants_controller_spec.rb:3) – 00:21.220 of 00:41.407 (222)
BookedSlotsController (./spec/controllers/booked_slots_controller_spec.rb:3) – 00:15.729 of 00:27.893 (50)
Analytics::Wor...rsion::Summary (./spec/services/analytics/workflow_conversion/summary_spec.rb:3) – 00:15.383 of 00:15.914 (12)


Top 5 slowest suites (by `let` time):

FunnelsController (./spec/controllers/funnels_controller_spec.rb:3) – 00:38.532 of 00:43.649 (133)
 ↳ user – 3
 ↳ funnel – 2
ApplicantsController (./spec/controllers/applicants_controller_spec.rb:3) – 00:33.252 of 00:41.407 (222)
 ↳ user – 10
 ↳ funnel – 5
 ↳ applicant – 2
Webhooks::DispatchTransition (./spec/services/webhooks/dispatch_transition_spec.rb:3) – 00:30.320 of 00:33.706 (327)
 ↳ user – 30
BookedSlotsController (./spec/controllers/booked_slots_controller_spec.rb:3) – 00:25.710 of 00:27.893 e(50)
 ↳ user – 21
 ↳ stage – 14
AvailableSlotsController (./spec/controllers/available_slots_controller_spec.rb:3) – 00:18.481 of 00:23.366 (85)
 ↳ user – 15
 ↳ stage – 10
```

As you can see, the `let` profiler also tracks the provides the information on how many times each `let` declarations has been used within a group (shows top-3 by default).

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

You can also track only `let` or `before` usage by specifying `RD_PROF=let` and `RD_PROF=before` respectively.

For `let` profiler you can also specify the number of top `let` declarations to print through `RD_PROF_LET_TOP=10` env var.

To disable `let` stats add:

```ruby
TestProf::RSpecDissect.configure do |config|
  config.let_stats_enabled = false
end
```

## Using with RSpecStamp

RSpecDissect can be used with [RSpec Stamp](../recipes/rspec_stamp.md) to automatically mark _slow_ examples with custom tags. For example:

```sh
RD_PROF=1 RD_PROF_STAMP="slow" rspec ...
```

After running the command above the slowest example groups would be marked with the `:slow` tag.
