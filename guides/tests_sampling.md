# Tests Sampling

Sometimes it's useful to run profilers against randomly chosen tests. Unfortunetaly, test frameworks don's support such functionality. That's why we've included small patches for RSpec and Minitest in TestProf.


## Instructions

Require the corresponding patch:

```ruby
# For RSpec in your spec_helper.rb
require 'test_prof/recipes/rspec/sample'

# For Minitest in your test_helper.rb
require 'test_prof/recipes/minitest/sample'
```

And then just add `SAMPLE` env variable with the number of example groups (or suites) you want to run:

```sh
SAMPLE=10 rspec
```

That's it. Enjoy!
