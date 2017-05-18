# frozen_string_literal: true

require "test_prof/version"
require "test_prof/logging"

# Ruby applications tests profiling tools.
#
# Contains tools to anylyze factories usage, integrate with Ruby profilers,
# profile your examples using ActiveSupport notifications (if any) and
# statically analyze your code with custom Rubocop cops.
#
# Example usage:
#
#   require 'test_prof'
#
#   # Activate a tool by providing environment variable, e.g.
#   TEST_RUBY_PROF=1 rspec ...
#
#   # or manually in your code
#   TestProf::RubyProf.run
#
# See other modules for more examples.
module TestProf
  class << self
    include Logging

    def config
      @config ||= Configuration.new
    end

    def configure
      yield config
    end

    # Require gem and shows a custom
    # message if it fails to load
    def require(gem_name, msg)
      Kernel.require gem_name
      true
    rescue LoadError
      log :error, msg
      false
    end
  end

  # TestProf configuration
  class Configuration
    attr_accessor :output, # IO to write output messages.
                  :color   # Whether to colorize output or not

    def initialize
      @output = $stdout
      @color = true
    end

    def color?
      color == true
    end
  end
end
