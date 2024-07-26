# frozen_string_literal: true

RSpec.configure do |config|
  report = nil

  config.append_before(:suite) do
    report = TestProf::RubyProf.profile(locked: true)

    TestProf.log :info, "RubyProf enabled for examples"
  end

  config.after(:suite) do
    report&.dump("examples")
  end
end
