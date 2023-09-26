# MemoryProf

MemoryProf tracks memory usage during your test suite run, and can help to detect test examples and groups that cause memory spikes. Memory profiling supports two metrics: RSS and allocations.

Example output:

```sh
[TEST PROF INFO] MemoryProf results

Final RSS: 673KB

Top 5 groups (by RSS):

AnswersController (./spec/controllers/answers_controller_spec.rb:3) – +80KB (13.50%)
QuestionsController (./spec/controllers/questions_controller_spec.rb:3) – +32KB  (9.08%)
CommentsController (./spec/controllers/comments_controller_spec.rb:3) – +16KB (3.27%)

Top 5 examples (by RSS):

destroys question (./spec/controllers/questions_controller_spec.rb:38) – +144KB (24.38%)
change comments count (./spec/controllers/comments_controller_spec.rb:7) – +120KB (20.00%)
change Votes count (./spec/shared_examples/controllers/voted_examples.rb:23) – +90KB (16.36%)
change Votes count (./spec/shared_examples/controllers/voted_examples.rb:23) – +64KB (12.86%)
fails (./spec/shared_examples/controllers/invalid_examples.rb:3) – +32KB (5.00%)
```

The examples block shows the amount of memory used by each example, and the groups block displays the memory allocated by other code defined in the groups. For example, RSpec groups may include heavy `before(:all)` (or `before_all`) setup blocks, so it is helpful to see which groups use the most amount of memory outside of their examples.

## Instructions

To activate MemoryProf with:

### RSpec

Use `TEST_MEM_PROF` environment variable to set which metric to use:

```sh
TEST_MEM_PROF='rss' rspec ...
TEST_MEM_PROF='alloc' rake rspec ...
```

### Minitest

Use `TEST_MEM_PROF` environment variable to set which metric to use:

```sh
TEST_MEM_PROF='rss' rake test
TEST_MEM_PROF='alloc' rspec ...
```

or use CLI options as well:

```sh
# Run a specific file using CLI option
ruby test/my_super_test.rb --mem-prof=rss

# Show the list of possible options:
ruby test/my_super_test.rb --help
```

## Configuration

By default, MemoryProf tracks the top 5 examples and groups that use the largest amount of memory.
You can set how many examples/groups to display with the option:

```sh
TEST_MEM_PROF='rss' TEST_MEM_PROF_COUNT=10 rspec ...
```

or with CLI options for Minitest:

```sh
# Run a specific file using CLI option
ruby test/my_super_test.rb --mem-prof=rs --mem-prof-top-count=10
```

## Supported Ruby Engines & OS

Currently the allocation mode is not supported for JRuby.

Since RSS depends on the OS, MemoryProf uses different tools to retrieve it:

* Linux – `/proc/$pid/statm` file,
* macOS, Solaris, BSD – `ps`,
* Windows – `Get-Process`, requires PowerShell to be installed.
