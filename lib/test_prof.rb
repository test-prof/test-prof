# frozen_string_literal: true

require "fileutils"
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

    # Run block only if provided env var is present and
    # equal to the provided value (if any).
    # Contains workaround for applications using Spring.
    def activate(env_var, val = nil)
      if defined?(::Spring)
        ::Spring.after_fork { activate!(env_var, val) { yield } }
      else
        activate!(env_var, val) { yield }
      end
    end

    # Return absolute path to asset
    def asset_path(filename)
      ::File.expand_path(filename, ::File.join(::File.dirname(__FILE__), "..", "assets"))
    end

    # Return a path to store artefact
    def artefact_path(filename)
      with_timestamps(
        ::File.join(
          config.output_dir,
          filename
        )
      )
    end

    private

    def activate!(env_var, val)
      yield if ENV[env_var] && (val.nil? || ENV[env_var] == val)
    end

    def with_timestamps(path)
      return path unless config.timestamps?
      timestamps = "-#{Time.now.to_i}"
      "#{path.sub(/\.\w+$/, '')}#{timestamps}#{::File.extname(path)}"
    end
  end

  # TestProf configuration
  class Configuration
    attr_accessor :output,      # IO to write output messages.
                  :color,       # Whether to colorize output or not
                  :output_dir,  # Directory to store artifacts
                  :timestamps   # Whethere to use timestamped names for artifacts

    def initialize
      @output = $stdout
      @color = true
      @output_dir = "tmp"
      @timestamps = false
    end

    def output_dir=(path)
      FileUtils.mkdir_p path
      @output_dir = path
    end

    def color?
      color == true
    end

    def timestamps?
      timestamps == true
    end
  end
end

require "test_prof/ruby_prof"
require "test_prof/stack_prof"
require "test_prof/event_prof"
require "test_prof/factory_doctor"
require "test_prof/factory_prof"
require "test_prof/rspec_stamp"
require "test_prof/tag_prof"
