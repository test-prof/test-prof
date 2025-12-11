# frozen_string_literal: true

require "test_prof"

# For RuboCop plugin
if defined?(RuboCop)
  module RuboCop
    autoload :TestProf, "rubocop/test_prof"
  end
end
