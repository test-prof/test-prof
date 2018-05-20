[![Gem Version](https://badge.fury.io/rb/test-prof.svg)](https://rubygems.org/gems/test-prof) [![Build Status](https://travis-ci.org/palkan/test-prof.svg?branch=master)](https://travis-ci.org/palkan/test-prof) [![Code Triagers Badge](https://www.codetriage.com/palkan/test-prof/badges/users.svg)](https://www.codetriage.com/palkan/test-prof)
[![Documentation](https://img.shields.io/badge/docs-link-brightgreen.svg)](https://test-prof.evilmartians.io)

# Ruby Tests Profiling Toolbox

<img align="right" height="150" width="129"
     title="TestProf logo" src="./docs/assets/images/logo.svg">

TestProf is a collection of different tools to analyze your test suite performance.

Why does test suite performance matter? First of all, testing is a part of a developer's feedback loop (see [@searls](https://github.com/searls) [talk](https://vimeo.com/145917204)) and, secondly, it is a part of a deployment cycle.

Simply speaking, slow tests waste your time making you less productive.

TestProf toolbox aims to help you identify bottlenecks in your test suite. It contains:

- Plug'n'Play integrations for general Ruby profilers ([`ruby-prof`](https://github.com/ruby-prof/ruby-prof), [`stackprof`](https://github.com/tmm1/stackprof))

- Factories usage analyzers and profilers

- ActiveSupport-backed profilers

- RuboCop cops

- etc.

Of course, we have some [solutions](https://test-prof.evilmartians.io/#/?id=recipes) for common performance issues too, bundled into the gem.

[![](./docs/assets/images/coggle.png)](http://bit.ly/test-prof-map)

📑 [Documentation](https://test-prof.evilmartians.io)

Supported Ruby versions:

- Ruby (MRI) >= 2.2.0

- JRuby >= 9.1.0.0

<a href="https://evilmartians.com/">
<img src="https://evilmartians.com/badges/sponsored-by-evil-martians.svg" alt="Sponsored by Evil Martians" width="236" height="54"></a>

## Resources

- RailsClub, Moscow, 2017, "Faster Tests" talk [[video](https://www.youtube.com/watch?v=8S7oHjEiVzs) (RU), [slides](https://speakerdeck.com/palkan/railsclub-moscow-2017-faster-tests)]

- [TestProf: a good doctor for slow Ruby tests](https://evilmartians.com/chronicles/testprof-a-good-doctor-for-slow-ruby-tests)

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

## Usage

Check out our [docs][].

## What's next?

Have an idea? [Propose](https://github.com/palkan/test-prof/issues/new) a feature request!


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

[docs]: https://test-prof.evilmartians.io
