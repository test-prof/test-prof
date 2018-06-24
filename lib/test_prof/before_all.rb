# frozen_string_literal: true

module TestProf
  # `before_all` helper configiration
  module BeforeAll
    class AdapterMissing < StandardError # :nodoc:
      MSG = "Please, provide an adapter for `before_all` " \
            "through `TestProf::BeforeAll.adapter = MyAdapter`".freeze

      def initialize
        super(MSG)
      end
    end

    class << self
      attr_accessor :adapter

      def begin_transaction
        raise AdapterMissing if adapter.nil?
        adapter.begin_transaction
      end

      def rollback_transaction
        raise AdapterMissing if adapter.nil?
        adapter.rollback_transaction
      end
    end
  end
end

if defined?(::ActiveRecord::Base)
  require "test_prof/before_all/adapters/active_record"

  TestProf::BeforeAll.adapter = TestProf::BeforeAll::Adapters::ActiveRecord
end
