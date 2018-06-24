# frozen_string_literal: true

require "test_prof/factory_bot"
require "test_prof/factory_default/factory_bot_patch"

module TestProf
  # FactoryDefault allows use to re-use associated objects
  # in factories implicilty
  module FactoryDefault
    module DefaultSyntax # :nodoc:
      def create_default(name, *args, &block)
        obj = TestProf::FactoryBot.create(name, *args, &block)
        return obj if FactoryDefault.preserve_traits
        set_factory_default(name, obj)
      end

      def set_factory_default(name, obj)
        FactoryDefault.register(name, obj)
      end
    end

    class << self
      attr_accessor :preserve_traits

      def init
        TestProf::FactoryBot::Syntax::Methods.include DefaultSyntax
        TestProf::FactoryBot.extend DefaultSyntax
        TestProf::FactoryBot::Strategy::Create.prepend StrategyExt
        TestProf::FactoryBot::Strategy::Build.prepend StrategyExt
        TestProf::FactoryBot::Strategy::Stub.prepend StrategyExt

        @store = {}
        # by default should be false for backward compatibility
        @preserve_traits = false
      end

      def register(name, obj)
        store[name] = obj
      end

      def get(name)
        store[name]
      end

      def exists?(name)
        store.key?(name)
      end

      def remove(name)
        store.delete(name)
      end

      def reset
        @store.clear
      end

      private

      attr_reader :store
    end
  end
end
