# frozen_string_literal: true

require "test_prof/factory_default/factory_girl_patch"

module TestProf
  # FactoryDefault allows use to re-use associated objects
  # in factories implicilty
  module FactoryDefault
    module DefaultSyntax # :nodoc:
      def create_default(name, *args, &block)
        set_factory_default(
          name,
          FactoryGirl.create(name, *args, &block)
        )
      end

      def set_factory_default(name, obj)
        FactoryDefault.register(name, obj)
      end
    end

    class << self
      def init
        FactoryGirl::Syntax::Methods.include DefaultSyntax
        FactoryGirl.extend DefaultSyntax
        FactoryGirl::Strategy::Create.prepend StrategyExt
        FactoryGirl::Strategy::Build.prepend StrategyExt
        FactoryGirl::Strategy::Stub.prepend StrategyExt

        @store = {}
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
