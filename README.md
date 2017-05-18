[![Gem Version](https://badge.fury.io/rb/test-prof.svg)](https://rubygems.org/gems/test-prof) [![Build Status](https://travis-ci.org/palkan/test-prof.svg?branch=master)](https://travis-ci.org/palkan/test-prof)

# Ruby Tests Profiling Toolbox

TestProf is a collection of different tools to analyze your test suite performance:

- Plug'n'Play integrations for general Ruby profilers ([`ruby-prof`](https://github.com/ruby-prof), [`stackprof`](https://github.com/tmm1/stackprof))

- Factories usage analyzers and profilers

- ActiveSupport-backed profilers

- Rubocop cops

- etc.

Of course, we have some [solutions](#tips-and-tricks) for common performance issues too, bundled into the gem.

See [Table of Contents](#table-of-contents) for more.

<a href="https://evilmartians.com/">
<img src="https://evilmartians.com/badges/sponsored-by-evil-martians.svg" alt="Sponsored by Evil Martians" width="236" height="54"></a>

## Resources

- RubyConfBy, 2017, "Run Test Run" talk [[video](https://www.youtube.com/watch?v=q52n4p0wkIs), [slides](https://speakerdeck.com/palkan/rubyconfby-minsk-2017-run-test-run)]

## Installation

Add `test-prof` gem to your application:

```ruby
group :test do
  gem 'test-prof'
end
```

And that's it)

## Table of Contents

Checkout our guides for each specific tool:

- [RubyProf Integration](https://github.com/palkan/test-prof/tree/master/guides/ruby_prof.md)

- StackProf Integration

- ActiveSupport events profiler

- Factory Doctor

- Factory Profiler

## Tips and Tricks

We also want to share some small code tricks which can help you to improve your test suite performance and efficiency:

- `before_all` Hook

- Any Fixture

- `bulletify`

- [`rspec-sqlimit`](https://github.com/nepalez/rspec-sqlimit)

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

