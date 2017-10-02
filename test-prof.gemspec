# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'test_prof/version'

Gem::Specification.new do |spec|
  spec.name          = "test-prof"
  spec.version       = TestProf::VERSION
  spec.authors       = ["Vladimir Dementyev"]
  spec.email         = ["dementiev.vm@gmail.com"]
  spec.required_ruby_version = '>= 2.2.0'

  spec.summary       = "Ruby applications tests profiling tools"
  spec.description   = %{
    Ruby applications tests profiling tools.

    Contains tools to analyze factories usage, integrate with Ruby profilers,
    profile your examples using ActiveSupport notifications (if any) and
    statically analyze your code with custom Rubocop cops.
  }
  spec.homepage      = "http://github.com/palkan/test-prof"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/).select { |p| p.match(%r{^(lib/|guides/|assets/[^\/]+)}) } +
    %w(README.md CHANGELOG.md LICENSE.txt)

  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.5"
  spec.add_development_dependency "minitest", "~> 5.9"
  spec.add_development_dependency "rubocop", "~> 0.50"
end
