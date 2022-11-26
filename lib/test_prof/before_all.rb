# frozen_string_literal: true

require "test_prof"

module TestProf
  # `before_all` helper configuration
  module BeforeAll
    class AdapterMissing < StandardError # :nodoc:
      MSG = "Please, provide an adapter for `before_all` " \
            "through `TestProf::BeforeAll.adapter = MyAdapter`"

      def initialize
        super(MSG)
      end
    end

    class << self
      attr_accessor :adapter

      def begin_transaction(scope = nil)
        raise AdapterMissing if adapter.nil?

        config.run_hooks(:begin, scope) do
          adapter.begin_transaction
        end
        yield
      end

      def rollback_transaction(scope = nil)
        raise AdapterMissing if adapter.nil?

        config.run_hooks(:rollback, scope) do
          adapter.rollback_transaction
        end
      end

      def setup_fixtures(test_object)
        raise ArgumentError, "Current adapter doesn't support #setup_fixtures" unless adapter.respond_to?(:setup_fixtures)

        adapter.setup_fixtures(test_object)
      end

      def config
        @config ||= Configuration.new
      end

      def configure
        yield config
      end
    end

    class HooksChain # :nodoc:
      attr_reader :type, :after, :before

      def initialize(type)
        @type = type
        @before = []
        @after = []
      end

      def run(scope = nil)
        before.each { |clbk| clbk.call(scope) }
        yield
        after.each { |clbk| clbk.call(scope) }
      end
    end

    class Configuration
      HOOKS = %i[begin rollback].freeze

      attr_accessor :setup_fixtures

      def initialize
        @hooks = Hash.new { |h, k| h[k] = HooksChain.new(k) }
        @setup_fixtures = false
      end

      # Add `before` hook for `begin` or
      # `rollback` operation:
      #
      #   config.before(:rollback) { ... }
      def before(type, &block)
        validate_hook_type!(type)
        hooks[type].before << block if block
      end

      # Add `after` hook for `begin` or
      # `rollback` operation:
      #
      #   config.after(:begin) { ... }
      def after(type, &block)
        validate_hook_type!(type)
        hooks[type].after << block if block
      end

      def run_hooks(type, scope = nil) # :nodoc:
        validate_hook_type!(type)
        hooks[type].run(scope) { yield }
      end

      private

      def validate_hook_type!(type)
        return if HOOKS.include?(type)

        raise ArgumentError, "Unknown hook type: #{type}. Valid types: #{HOOKS.join(", ")}"
      end

      attr_reader :hooks
    end
  end
end

if defined?(::ActiveRecord::Base)
  require "test_prof/before_all/adapters/active_record"

  TestProf::BeforeAll.adapter = TestProf::BeforeAll::Adapters::ActiveRecord
end

if defined?(::Isolator)
  require "test_prof/before_all/isolator"
end
