[![Gem Version](https://badge.fury.io/rb/test-prof.svg)](https://rubygems.org/gems/test-prof) [![Build](https://github.com/test-prof/test-prof/workflows/Build/badge.svg)](https://github.com/test-prof/test-prof/actions)
[![JRuby Build](https://github.com/test-prof/test-prof/workflows/JRuby%20Build/badge.svg)](https://github.com/test-prof/test-prof/actions)

# TestProf

> Ruby tests profiling and optimization toolbox

<img align="right" height="150" width="129"
     title="TestProf logo" class="home-logo" src="./assets/images/logo.svg">

TestProf is a collection of different tools to analyze your test suite performance.

Why does test suite performance matter? First of all, testing is a part of a developer's feedback loop (see [@searls](https://github.com/searls) [talk](https://vimeo.com/145917204)) and, secondly, it is a part of a deployment cycle.

Simply speaking, slow tests waste your time making you less productive.

TestProf toolbox aims to help you identify bottlenecks in your test suite. It contains:

- Plug'n'Play integration for general Ruby profilers ([`ruby-prof`](https://github.com/ruby-prof/ruby-prof), [`stackprof`](https://github.com/tmm1/stackprof))

- Factories usage analyzers and profilers

- ActiveSupport-backed profilers

- RSpec and minitest [helpers](#recipes) to write faster tests

- RuboCop cops

- etc.

📑 [Documentation](https://test-prof.evilmartians.io)

<p align="center">
  <a href="http://bit.ly/test-prof-map-v1">
    <img src="./assets/images/coggle.png" alt="TestProf map" width="738">
  </a>
</p>

<p align="center">
  <a href="https://evilmartians.com/?utm_source=test-prof">
    <img src="https://evilmartians.com/badges/sponsored-by-evil-martians.svg"
         alt="Sponsored by Evil Martians" width="236" height="54">
  </a>
</p>

## Who uses TestProf

- [Discourse](https://github.com/discourse/discourse) reduced [~27% of their test suite time](https://twitter.com/samsaffron/status/1125602558024699904)
- [Gitlab](https://gitlab.com/gitlab-org/gitlab-ce) reduced [39% of their API tests time](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/14370)
- [CodeTriage](https://github.com/codetriage/codetriage)
- [Dev.to](https://github.com/thepracticaldev/dev.to)
- [Open Project](https://github.com/opf/openproject)
- [...and others](https://github.com/test-prof/test-prof/issues/73)

## Resources

- [TestProf: a good doctor for slow Ruby tests](https://evilmartians.com/chronicles/testprof-a-good-doctor-for-slow-ruby-tests)

- [TestProf II: factory therapy for your Ruby tests](https://evilmartians.com/chronicles/testprof-2-factory-therapy-for-your-ruby-tests-rspec-minitest)

- [TestProf III: guided and automated Ruby test profiling](https://evilmartians.com/chronicles/test-prof-3-guided-and-automated-ruby-test-profiling)

- [Rails Testing on Rocket Fuel: How we made our tests 5x faster](https://www.zerogravity.co.uk/blog/ruby-on-rails-slow-tests)

- Paris.rb, 2018, "99 Problems of Slow Tests" talk [[video](https://www.youtube.com/watch?v=eDMZS_fkRtk), [slides](https://speakerdeck.com/palkan/paris-dot-rb-2018-99-problems-of-slow-tests)]

- BalkanRuby, 2018, "Take your slow tests to the doctor" talk [[video](https://www.youtube.com/watch?v=rOcrme82vC8)], [slides](https://speakerdeck.com/palkan/balkanruby-2018-take-your-slow-tests-to-the-doctor)]

- RailsClub, Moscow, 2017, "Faster Tests" talk [[video](https://www.youtube.com/watch?v=8S7oHjEiVzs) (RU), [slides](https://speakerdeck.com/palkan/railsclub-moscow-2017-faster-tests)]

- RubyConfBy, 2017, "Run Test Run" talk [[video](https://www.youtube.com/watch?v=q52n4p0wkIs), [slides](https://speakerdeck.com/palkan/rubyconfby-minsk-2017-run-test-run)]

- [Tips to improve speed of your test suite](https://medium.com/appaloosa-store-engineering/tips-to-improve-speed-of-your-test-suite-8418b485205c) by [Benoit Tigeot](https://github.com/benoittgt)

## Installation

Add `test-prof` gem to your application:

```ruby
group :test do
  gem "test-prof", "~> 1.0"
end
```

And that's it)

Supported Ruby versions:

- Ruby (MRI) >= 2.5.0 (**NOTE:** for Ruby 2.2 use TestProf < 0.7.0, Ruby 2.3 use TestProf ~> 0.7.0, Ruby 2.4 use TestProf <0.12.0)

- JRuby >= 9.1.0.0 (**NOTE:** refinements-dependent features might require 9.2.7+)

Supported RSpec version (for RSpec features only): >= 3.5.0 (for older RSpec version use TestProf < 0.8.0).

Supported Rails version (for Rails features only): >= 5.2.0 (for older Rails versions use TestProf < 1.0).

### Linting with RuboCop RSpec

When you lint your RSpec spec files with `rubocop-rspec`, it will fail to properly detect RSpec constructs that TestProf defines, `let_it_be` and `before_all`.
Make sure to use `rubocop-rspec` 2.0 or newer and add the following to your `.rubocop.yml`:

```yaml
inherit_gem:
  test-prof: config/rubocop-rspec.yml
```

## Profilers

- [RubyProf Integration](./profilers/ruby_prof.md)

- [StackProf Integration](./profilers/stack_prof.md)

- [Event Profiler](./profilers/event_prof.md) (e.g. ActiveSupport notifications)

- [Tag Profiler](./profilers/tag_prof.md)

- [Factory Doctor](./profilers/factory_doctor.md)

- [Factory Profiler](./profilers/factory_prof.md)

- [RSpecDissect Profiler](./profilers/rspec_dissect.md)

## Recipes

We also want to share some small code tricks which can help you to improve your test suite performance and efficiency:

- [`before_all` Hook](./recipes/before_all.md)

- [`let_it_be` Helper](./recipes/let_it_be.md)

- [AnyFixture](./recipes/any_fixture.md)

- [FactoryDefault](./recipes/factory_default.md)

- [FactoryAllStub](./recipes/factory_all_stub.md)

- [RSpec Stamp](./recipes/rspec_stamp.md)

- [Tests Sampling](./recipes/tests_sampling.md)

- [Active Record Shared Connection](./recipes/active_record_shared_connection.md)

- [Rails Logging](./recipes/logging.md)

## Other tools

- [RuboCop cops](./misc/rubocop.md)

## What's next

Have an idea? [Propose](https://github.com/test-prof/test-prof/discussions) a feature request!

Already using TestProf? [Share your story!](https://github.com/test-prof/test-prof/discussions/73)

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
