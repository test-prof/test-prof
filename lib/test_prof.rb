# frozen_string_literal: true
# Test jruby

require "test_prof/version"
require "test_prof/core"

require "test_prof/ruby_prof"
require "test_prof/stack_prof"
require "test_prof/event_prof"
require "test_prof/factory_doctor"
require "test_prof/factory_prof"
require "test_prof/rspec_stamp"
require "test_prof/tag_prof"
require "test_prof/rspec_dissect" if TestProf.rspec?
require "test_prof/factory_all_stub"
