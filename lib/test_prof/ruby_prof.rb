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
      PRINTERS = {
        "flat" => "FlatPrinter",
        "flat_wln" => "FlatPrinterWithLineNumbers",
        "graph" => "GraphPrinter",
        "graph_html" => "GraphHtmlPrinter",
        "dot" => "DotPrinter",
        "." => "DotPrinter",
        "call_stack" => "CallStackPrinter",
        "call_tree" => "CallTreePrinter",
        "multi" => "MultiPrinter"
      }.freeze

      # Mapping from printer to report file extension
      # NOTE: txt is not included and considered default
      PRINTER_EXTENSTION = {
        "graph_html" => "html",
        "dot" => "dot",
        "." => "dot",
        "call_stack" => "html"
      }.freeze

      LOGFILE_PREFIX = "ruby-prof-report"

      attr_accessor :printer, :mode, :min_percent,
        :include_threads, :exclude_common_methods,
        :test_prof_exclusions_enabled,
        :custom_exclusions, :skip_boot

      def initialize
        @printer = ENV["TEST_RUBY_PROF"].to_sym if PRINTERS.key?(ENV["TEST_RUBY_PROF"])
        @printer ||= ENV.fetch("TEST_RUBY_PROF_PRINTER", :flat).to_sym
        @mode = ENV.fetch("TEST_RUBY_PROF_MODE", :wall).to_s
        @skip_boot = %w[0 false f].include?(ENV["TEST_RUBY_PROF_BOOT"])
        @min_percent = 1
        @include_threads = false
        @exclude_common_methods = true
        @test_prof_exclusions_enabled = true
        @custom_exclusions = {}
      end

      def include_threads?
        include_threads == true
      end

      def skip_boot?
        skip_boot == true
      end

      def exclude_common_methods?
        exclude_common_methods == true
      end

      def test_prof_exclusions_enabled?
        @test_prof_exclusions_enabled == true
      end

      # Returns an array of printer type (ID) and class.
      def resolve_printer
        return ["custom", printer] if printer.is_a?(Module)

        type = printer.to_s

        raise ArgumentError, "Unknown printer: #{type}" unless
          PRINTERS.key?(type)

        [type, ::RubyProf.const_get(PRINTERS[type])]
      end

      # Based on deprecated https://github.com/ruby-prof/ruby-prof/blob/fd3a5236a459586c5ca7ce4de506c1835129516a/lib/ruby-prof.rb#L36
      def ruby_prof_mode
        case mode
        when "wall", "wall_time"
          ::RubyProf::WALL_TIME
        when "allocations"
          ::RubyProf::ALLOCATIONS
        when "memory"
          ::RubyProf::MEMORY
        when "process", "process_time"
          ::RubyProf::PROCESS_TIME
        else
          ::RubyProf::WALL_TIME
        end
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

        printer_type, printer_class = config.resolve_printer

        if %w[call_tree multi].include?(printer_type)
          path = TestProf.create_artifact_dir
          printer_class.new(result).print(
            path: path,
            profile: "#{RubyProf::Configuration::LOGFILE_PREFIX}-#{printer_type}-" \
              "#{config.mode}-#{name}",
            min_percent: config.min_percent
          )
        else
          path = build_path name, printer_type
          File.open(path, "w") do |f|
            printer_class.new(result).print(f, min_percent: config.min_percent)
          end

        end

        log :info, "RubyProf report generated: #{path}"
      end

      private

      def build_path(name, printer)
        TestProf.artifact_path(
          "#{RubyProf::Configuration::LOGFILE_PREFIX}-#{printer}-#{config.mode}-#{name}" \
          ".#{RubyProf::Configuration::PRINTER_EXTENSTION.fetch(printer, "txt")}"
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
        report = profile(locked: true)

        return unless report

        log :info, "RubyProf enabled globally"

        at_exit { report.dump("total") }
      end

      def profile(locked: false)
        if locked?
          log :warn, <<~MSG
            RubyProf is activated globally, you cannot generate per-example report.

            Make sure you haven not set the TEST_RUBY_PROF environmental variable.
          MSG
          return
        end

        return unless init_ruby_prof

        options = {}

        options[:include_threads] = [Thread.current] unless
          config.include_threads?
        options[:measure_mode] = config.ruby_prof_mode

        profiler = ::RubyProf::Profile.new(options)
        profiler.exclude_common_methods! if config.exclude_common_methods?

        if config.test_prof_exclusions_enabled?
          # custom test-prof exclusions
          exclude_rspec_methods(profiler)

          # custom global exclusions
          exclude_common_methods(profiler)
        end

        config.custom_exclusions.each do |klass, mids|
          profiler.exclude_methods! klass, *mids
        end

        profiler.start

        @locked = true if locked

        Report.new(profiler)
      end

      private

      def locked?
        @locked == true
      end

      def init_ruby_prof
        return @initialized if instance_variable_defined?(:@initialized)
        @initialized = TestProf.require(
          "ruby-prof",
          <<~MSG
            Please, install 'ruby-prof' first:
               # Gemfile
              gem 'ruby-prof', '>= 1.4.0', require: false
          MSG
        ) { check_ruby_prof_version }
      end

      def check_ruby_prof_version
        if Utils.verify_gem_version("ruby-prof", at_least: "0.17.0")
          true
        else
          log :error, <<~MGS
            Please, upgrade 'ruby-prof' to version >= 0.17.0.
          MGS
          false
        end
      end

      def exclude_rspec_methods(profiler)
        return unless TestProf.rspec?

        RSpecExclusions.generate.each do |klass, mids|
          profiler.exclude_methods!(klass, *mids)
        end
      end

      def exclude_common_methods(profiler)
        if defined?(TSort)
          profiler.exclude_methods!(
            TSort,
            :tsort_each
          )

          profiler.exclude_methods!(
            TSort.singleton_class,
            :tsort_each, :each_strongly_connected_component,
            :each_strongly_connected_component_from
          )
        end

        profiler.exclude_methods!(
          BasicObject,
          :instance_exec
        )
      end
    end
  end
end

if TestProf.rspec?
  require "test_prof/ruby_prof/rspec"
  require "test_prof/ruby_prof/rspec_exclusions"
end

# Hook to run RubyProf globally
TestProf.activate("TEST_RUBY_PROF") do
  if TestProf::RubyProf.config.skip_boot?
    if TestProf.rspec?
      require "test_prof/ruby_prof/rspec_no_boot"
    else
      TestProf.log :warn, "RubyProf tests profiling w/o test suite boot is only supported in RSpec"
    end
  else
    TestProf::RubyProf.run
  end
end
