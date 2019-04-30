# frozen_string_literal: true

module TestProf
  # `before_all` helper configiration
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
        adapter.begin_transaction
        config.run_setup
        yield
      end

      def within_transaction
        yield
      end

      def rollback_transaction
        raise AdapterMissing if adapter.nil?
        adapter.rollback_transaction
      end

      def config
        @config ||= Configuration.new
      end

      def configure
        yield config
      end
    end

    class Hook
      def initialize
        @cbs = []
      end

      def on(&blk)
        @cbs << blk
      end

      def run
        @cbs.each(&:call)
      end
    end

    class Configuration
      def initialize
        @setup_before_all_hook = Hook.new
      end

      def setup_before_all(&blk)
        @setup_before_all_hook.on(&blk)
      end

      def run_setup
        @setup_before_all_hook.run
      end
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
