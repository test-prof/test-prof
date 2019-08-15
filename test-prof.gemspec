# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "test_prof/version"

Gem::Specification.new do |spec|
  spec.name = "test-prof"
  spec.version = TestProf::VERSION
  spec.authors = ["Vladimir Dementyev"]
  spec.email = ["dementiev.vm@gmail.com"]

  spec.summary = "Ruby applications tests profiling tools"
  spec.description = %{
    Ruby applications tests profiling tools.

    Contains tools to analyze factories usage, integrate with Ruby profilers,
    profile your examples using ActiveSupport notifications (if any) and
    statically analyze your code with custom RuboCop cops.
  }
  spec.homepage = "http://github.com/palkan/test-prof"
  spec.license = "MIT"
  spec.metadata = {
    "bug_tracker_uri" => "http://github.com/palkan/test-prof/issues",
    "changelog_uri" => "https://github.com/palkan/test-prof/blob/master/CHANGELOG.md",
    "documentation_uri" => "https://test-prof.evilmartians.io/",
    "homepage_uri" => "https://test-prof.evilmartians.io/",
    "source_code_uri" => "http://github.com/palkan/test-prof"
  }

  spec.files = `git ls-files`.split($/).select { |p| p.match(%r{^(lib/|guides/|assets/[^\/]+)}) } +
    %w[README.md CHANGELOG.md LICENSE.txt]

  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.4.0"

  spec.add_development_dependency "bundler", ">= 1.10"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "rspec", "~> 3.4"
  spec.add_development_dependency "isolator", "~> 0.6"
  spec.add_development_dependency "minitest", "~> 5.9"
  spec.add_development_dependency "rubocop-md", "~> 0.2"
  spec.add_development_dependency "standard", "~> 0.1.0"
end
