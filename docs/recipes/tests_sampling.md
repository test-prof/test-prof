# Tests Sampling

Sometimes it's useful to run profilers against randomly chosen tests. Unfortunately, test frameworks don't support such functionality. That's why we've included small patches for RSpec and Minitest in TestProf.

## Instructions

Require the corresponding patch:

```ruby
# For RSpec in your spec_helper.rb
require "test_prof/recipes/rspec/sample"

# For Minitest in your test_helper.rb
require "test_prof/recipes/minitest/sample"
```

And then just add `SAMPLE` env variable with the number examples you want to run:

```sh
SAMPLE=10 rspec
```

You can also run random set of example groups (or suites) using `SAMPLE_GROUPS` variable:

```sh
SAMPLE_GROUPS=10 rspec
```

Note that you can use tests sampling with RSpec filters:

```sh
SAMPLE=10 rspec --tag=api
SAMPLE_GROUPS=10 rspec -e api
```

That's it. Enjoy!
