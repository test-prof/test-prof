# frozen_string_literal: true

module TestProf
  module TagProf # :nodoc:
  end
end

require "test_prof/tag_prof/rspec" if defined?(RSpec::Core)
