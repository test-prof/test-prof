# frozen_string_literal: true

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

      def begin_transaction
        raise AdapterMissing if adapter.nil?

        config.run_hooks(:begin) do
          adapter.begin_transaction
        end
        yield
      end

      def within_transaction
        yield
      end

      def rollback_transaction
        raise AdapterMissing if adapter.nil?

        config.run_hooks(:rollback) do
          adapter.rollback_transaction
        end
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

      def run
        before.each(&:call)
        yield
        after.each(&:call)
      end
    end

    class Configuration
      HOOKS = %i[begin rollback].freeze

      def initialize
        @hooks = Hash.new { |h, k| h[k] = HooksChain.new(k) }
      end

      # Add `before` hook for `begin` or
      # `rollback` operation:
      #
      #   config.before(:rollback) { ... }
      def before(type, &block)
        validate_hook_type!(type)
        hooks[type].before << block if block_given?
      end

      # Add `after` hook for `begin` or
      # `rollback` operation:
      #
      #   config.after(:begin) { ... }
      def after(type, &block)
        validate_hook_type!(type)
        hooks[type].after << block if block_given?
      end

      def run_hooks(type) # :nodoc:
        validate_hook_type!(type)
        hooks[type].run { yield }
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
