# FactoryAllStub

_Factory All Stub_ is a spell to force FactoryBot/FactoryGirl use only `build_stubbed` strategy (even if you call `create` or `build`).

The idea behind it is to quickly fix [Factory Doctor](../profilers/factory_doctor.md) offenses (and even do that automatically).

**NOTE**. Only works with FactoryGirl/FactoryBot. Should be considered only as a temporary specs fix.

## Instructions

First, you have to initialize `FactoryAllStub`:

```ruby
TestProf::FactoryAllStub.init
```

The initialization process injects custom logic into FactoryBot generator.

To enable _all-stub_ mode:

```ruby
TestProf::FactoryAllStub.enable!
```

To disable _all-stub_ mode and use factories as always:

```ruby
TestProf::FactoryAllStub.disable!
```

## RSpec

In your `spec_helper.rb` (or `rails_helper.rb` if any):

```ruby
require "test_prof/recipes/rspec/factory_all_stub"
```

That would automatically initialize `FactoryAllStub` (no need to call `.init`) and provide
`"factory:stub"` shared context with enables it for the marked examples or example groups:

```ruby
describe "User" do
  let(:user) { create(:user) }

  it "is valid", factory: :stub do
    # use `build_stubbed` instead of `create`
    expect(user).to be_valid
  end
end
```

`FactoryAllStub` was designed to be used with `FactoryDoctor` the following way:

```sh
# Run FactoryDoctor and mark all offensive examples with factory:stub
FDOC=1 FDOC_STAMP=factory:stub rspec ./spec/models
```
