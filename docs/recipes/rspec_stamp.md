# RSpecStamp

RSpecStamp is a tool to automatically _tag_ failed examples with custom tags.

It _literally_ adds tags to your examples (i.e. rewrites them).

The main purpose of RSpecStamp is to make testing codebase refactoring easy. Changing global configuration may cause a lot of failures. You can patch failing spec by adding a shared context. And here comes RSpecStamp.

## Example Use Case: Sidekiq Inline

Using `Sidekiq::Testing.inline!` may be considered a _bad practice_ (see [here](https://github.com/mperham/sidekiq/issues/3495)) due to its negative performance impact. But it's still widely used.

How to migrate from `inline!` to `fake!`?

Step 0. Make sure that all your tests pass.

Step 1. Create a shared context to conditionally turn on `inline!` mode:

```ruby
shared_context "sidekiq:inline", sidekiq: :inline do
  around(:each) { |ex| Sidekiq::Testing.inline!(&ex) }
end
```

Step 2. Turn on `fake!` mode globally.

Step 3. Run `RSTAMP=sidekiq:inline rspec`.

The output of the command above contains information about the _stamping_ process:

- How many files have been affected?

- How many patches were made?

- How many patches failed?

- How many files have been ignored?

Now all (or almost all) failing specs are tagged with `sidekiq: :inline`. Run the whole suite again and check it there are any failures left.

There is also a `dry-run` mode (activated by `RSTAMP_DRY_RUN=1` env variable) which prints out patches instead of re-writing files.

## Configuration

By default, RSpecStamp ignores examples located in `spec/support` directory (typical place to put shared examples in).
You can add more _ignore_ patterns:

```ruby
TestProf::RSpecStamp.configure do |config|
  config.ignore_files << %r{spec/my_directory}
end
```
