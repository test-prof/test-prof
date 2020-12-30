# Active Record Shared Connection

> 💀  This functionality has been removed in v1.0.

**NOTE:** a similar functionality has been added to Rails since version 5.1 (see [PR](https://github.com/rails/rails/pull/28083)). You shouldn't use `ActiveRecordSharedConnection` with modern Rails, it could lead to unexpected behaviour (e.g., mutexes deadlocks).

Active Record creates a connection per thread by default.

That doesn't allow us to use `transactional_tests` feature in system (with Capybara) tests (since Capybara runs a web server in a separate thread).

A common approach is to use `database_cleaner` with a non-transactional strategy (`truncation` / `deletion`). But that _cleaning_ phase may affect tests run time (and usually does).

Sharing the connection between threads would allows us to use transactional tests as always.

## Instructions

In your `spec_helper.rb` (or `rails_helper.rb` if any):

```ruby
require "test_prof/recipes/active_record_shared_connection"
```

That automatically enables _shared connection_ mode.

You can enable/disable it manually:

```ruby
TestProf::ActiveRecordSharedConnection.enable!
TestProf::ActiveRecordSharedConnection.disable!
```
