# frozen_string_literal: true

require "test_prof/ext/active_support_call_template"

TestProf::EventProf::CustomEvents.register("callback.run") do
  TestProf::EventProf.monitor(
    TestProf::Filters::CallbackInvocation,
    "callback.run",
    :call,
    payload: ->(target, _value) { {label: "#{kind}_#{name} #{filter} (#{target.class})"} }
  )
end
