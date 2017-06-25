# frozen_string_literal: true

module TestProf
  # RubyProf wrapper.
  #
  # Has 2 modes: global and per-example.
  #
  # Example:
  #
  #   # To activate global profiling you can use env variable
  #   TEST_RUBY_PROF=1 rspec ...
  #
  #   # or in your code
  #   TestProf::RubyProf.run
  #
  # To profile a specific examples add :rprof tag to it:
  #
  #   it "is doing heavy stuff", :rprof do
  #     ...
  #   end
  #
  module RubyProf
    # RubyProf configuration
    class Configuration
      # Default list of methods to exclude from profile.
      # Contains a lot of RSpec stuff.
      ELIMINATE_METHODS = [
        /instance_exec/,
        /ExampleGroup>?#run/,
        /Procsy/,
        /AroundHook#execute_with/,
        /HookCollections/,
        /Array#(map|each)/
      ].freeze

      PRINTERS = {
        'flat' => 'FlatPrinter',
        'flat_wln' => 'FlatWithLineNumbers',
        'graph' => 'GraphPrinter',
        'graph_html' => 'GraphHtmlPrinter',
        'dot' => 'DotPrinter',
        '.' => 'DotPrinter',
        'call_stack' => 'CallStackPrinter',
        'call_tree' => 'CallTreePrinter'
      }.freeze

      attr_accessor :printer, :mode, :min_percent,
                    :include_threads, :eliminate_methods

      def initialize
        @printer = :call_stack
        @mode = :wall
        @min_percent = 1
        @include_threads = false
        @eliminate_methods = ELIMINATE_METHODS
      end

      def include_threads?
        include_threads == true
      end

      def eliminate_methods?
        !eliminate_methods.nil? &&
          !eliminate_methods.empty?
      end

      # Returns an array of printer type (ID) and class.
      # Takes ENV variable TEST_RUBY_PROF_PRINTER into account.
      def resolve_printer
        type = ENV['TEST_RUBY_PROF_PRINTER'] || printer

        return ['custom', type] if type.is_a?(Module)

        type = type.to_s

        raise ArgumentError, "Unknown printer: #{type}" unless
          PRINTERS.key?(type)

        [type, ::RubyProf.const_get(PRINTERS[type])]
      end
    end

    # Wrapper over RubyProf profiler and printer
    class Report
      include TestProf::Logging

      def initialize(profiler)
        @profiler = profiler
      end

      # Stop profiling and generate the report
      # using provided name.
      def dump(name)
        result = @profiler.stop

        if config.eliminate_methods?
          result.eliminate_methods!(config.eliminate_methods)
        end

        printer_type, printer_class = config.resolve_printer
        path = build_path name, printer_type

        File.open(path, 'w') do |f|
          printer_class.new(result).print(f, min_percent: config.min_percent)
        end

        log :info, "RubyProf report generated: #{path}"
      end

      private

      def build_path(name, printer)
        TestProf.with_timestamps(
          File.join(
            TestProf.config.output_dir,
            "ruby-prof-report-#{printer}-#{config.mode}-#{name}.html"
          )
        )
      end

      def config
        RubyProf.config
      end
    end

    class << self
      include Logging

      def config
        @config ||= Configuration.new
      end

      def configure
        yield config
      end

      # Run RubyProf and automatically dump
      # a report when the process exits.
      #
      # Use this method to profile the whole run.
      def run
        report = profile

        return unless report

        @locked = true

        log :info, "RubyProf enabled"

        at_exit { report.dump("total") }
      end

      def profile
        return if locked?
        return unless init_ruby_prof

        options = {
          merge_fibers: true
        }

        options[:include_threads] = [Thread.current] unless
          config.include_threads?

        profiler = ::RubyProf::Profile.new(options)
        profiler.start

        Report.new(profiler)
      end

      private

      def locked?
        @locked == true
      end

      def init_ruby_prof
        return @initialized if instance_variable_defined?(:@initialized)
        ENV["RUBY_PROF_MEASURE_MODE"] = config.mode.to_s
        @initialized = TestProf.require(
          'ruby-prof',
          <<~MSG
            Please, install 'ruby-prof' first:
               # Gemfile
              gem 'ruby-prof', require: false
          MSG
        )
      end
    end
  end
end

require "test_prof/ruby_prof/rspec" if defined?(RSpec)

# Hook to run RubyProf globally
TestProf.activate('TEST_RUBY_PROF') do
  TestProf::RubyProf.run
end
