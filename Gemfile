source 'https://rubygems.org'

# Specify your gem's dependencies in test-prof.gemspec
gemspec

eval_gemfile "gemfiles/rubocop.gemfile"

local_gemfile = "Gemfile.local"

if File.exist?(local_gemfile)
  eval_gemfile(local_gemfile) # rubocop:disable Security/Eval
else
  gem "sqlite3", "~> 1.4"
  gem "activerecord", "~> 6.0"

  gem "factory_bot", "~> 5.0"
  gem "fabrication"

  gem "sidekiq", "~> 6.0"
  gem "timecop", "~> 0.9.1"

  gem "pry-byebug"
  gem "ruby-prof", ">= 0.16.0"
  gem "stackprof", ">= 0.2.9"
end
