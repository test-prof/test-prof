# frozen_string_literal: true

require "fileutils"
require "test_prof/version"
require "test_prof/logging"
require "test_prof/utils"

# Ruby applications tests profiling tools.
#
# Contains tools to anylyze factories usage, integrate with Ruby profilers,
# profile your examples using ActiveSupport notifications (if any) and
# statically analyze your code with custom RuboCop cops.
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

    # Avoid issues with wrong time due to monkey-patches (e.g. timecop)
    # See https://github.com/rspec/rspec-core/blob/v3.6.0/lib/rspec/core.rb#L147
    #
    # We also want to handle Timecop specificaly
    # See https://github.com/travisjeffery/timecop/blob/master/lib/timecop/time_extensions.rb#L11
    if Time.respond_to?(:now_without_mock_time)
      define_method(:now, &::Time.method(:now_without_mock_time))
    else
      define_method(:now, &::Time.method(:now))
    end

    # Require gem and shows a custom
    # message if it fails to load
    def require(gem_name, msg = nil)
      Kernel.require gem_name
      block_given? ? yield : true
    rescue LoadError
      log(:error, msg) if msg
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

    # Return a path to store artifact
    def artifact_path(filename)
      create_artifact_dir

      with_timestamps(
        ::File.join(
          config.output_dir,
          filename
        )
      )
    end

    def create_artifact_dir
      FileUtils.mkdir_p(config.output_dir)[0]
    end

    private

    def activate!(env_var, val)
      yield if ENV[env_var] && (val.nil? || ENV[env_var] == val)
    end

    def with_timestamps(path)
      return path unless config.timestamps?
      timestamps = "-#{now.to_i}"
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
      @output_dir = "tmp/test_prof"
      @timestamps = false
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
require "test_prof/rspec_dissect"
