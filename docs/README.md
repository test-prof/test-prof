[![Gem Version](https://badge.fury.io/rb/test-prof.svg)](https://rubygems.org/gems/test-prof) [![Build Status](https://travis-ci.org/palkan/test-prof.svg?branch=master)](https://travis-ci.org/palkan/test-prof)

# TestProf

> Ruby tests profiling and optimization toolbox

<img align="right" height="150" width="129"
     title="TestProf logo" class="home-logo" src="./assets/images/logo.svg">

TestProf is a collection of different tools to analyze your test suite performance.

Why does test suite performance matter? First of all, testing is a part of a developer's feedback loop (see [@searls](https://github.com/searls) [talk](https://vimeo.com/145917204)) and, secondly, it is a part of a deployment cycle.

Simply speaking, slow tests waste your time making you less productive.

TestProf toolbox aims to help you identify bottlenecks in your test suite. It contains:

- Plug'n'Play integrations for general Ruby profilers ([`ruby-prof`](https://github.com/ruby-prof/ruby-prof), [`stackprof`](https://github.com/tmm1/stackprof))

- Factories usage analyzers and profilers

- ActiveSupport-backed profilers

- RuboCop cops

- etc.

Of course, we have some [solutions](#recipes) for common performance issues too, bundled into the gem.

[![](./assets/images/coggle.png)](http://bit.ly/test-prof-map)

Supported Ruby versions:

- Ruby (MRI) >= 2.2.0

- JRuby >= 9.1.0.0

<a href="https://evilmartians.com/">
<img src="https://evilmartians.com/badges/sponsored-by-evil-martians.svg" alt="Sponsored by Evil Martians" width="236" height="54"></a>

## Resources

- [TestProf: a good doctor for slow Ruby tests](https://evilmartians.com/chronicles/testprof-a-good-doctor-for-slow-ruby-tests)

- [TestProf II: Factory therapy for your Ruby tests](https://evilmartians.com/chronicles/testprof-2-factory-therapy-for-your-ruby-tests-rspec-minitest)

- RailsClub, Moscow, 2017, "Faster Tests" talk [[video](https://www.youtube.com/watch?v=8S7oHjEiVzs) (RU), [slides](https://speakerdeck.com/palkan/railsclub-moscow-2017-faster-tests)]

- RubyConfBy, 2017, "Run Test Run" talk [[video](https://www.youtube.com/watch?v=q52n4p0wkIs), [slides](https://speakerdeck.com/palkan/rubyconfby-minsk-2017-run-test-run)]

- [Tips to improve speed of your test suite](https://medium.com/appaloosa-store-engineering/tips-to-improve-speed-of-your-test-suite-8418b485205c) by [Benoit Tigeot](https://github.com/benoittgt)

## Installation

Add `test-prof` gem to your application:

```ruby
group :test do
  gem 'test-prof'
end
```

And that's it)

## Profilers

- [RubyProf Integration](./ruby_prof.md)

- [StackProf Integration](./stack_prof.md)

- [Event Profiler](./event_prof.md) (e.g. ActiveSupport notifications)

- [Tag Profiler](./tag_prof.md)

- [Factory Doctor](./factory_doctor.md)

- [Factory Profiler](./factory_prof.md)

- [RSpecDissect Profiler](./rspec_dissect.md)

- [RuboCop cops](./rubocop.md)

## Recipes

We also want to share some small code tricks which can help you to improve your test suite performance and efficiency:

- [`before_all` Hook](./before_all.md)

- [`let_it_be` Helper](./let_it_be.md)

- [AnyFixture](./any_fixture.md)

- [FactoryDefault](./factory_default.md)

- [FactoryAllStub](./factory_all_stub.md)

- [RSpec Stamp](./rspec_stamp.md)

- [Tests Sampling](./tests_sampling.md)

- [Active Record Shared Connection](./active_record_shared_connection.md)

- [Rails Logging](./logging.md)

## What's next?

Have an idea? [Propose](https://github.com/palkan/test-prof/issues/new) a feature request!

Already using TestProf? [Share your story!](https://github.com/palkan/test-prof/issues/73)

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
