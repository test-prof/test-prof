# frozen_string_literal: true

require "test_prof/factory_bot"
require "test_prof/factory_default/factory_bot_patch"

module TestProf
  # FactoryDefault allows use to re-use associated objects
  # in factories implicilty
  module FactoryDefault
    module DefaultSyntax # :nodoc:
      def create_default(name, *args, &block)
        options = args.extract_options!
        preserve = options.delete(:preserve_traits) || FactoryDefault.preserve_traits

        obj = TestProf::FactoryBot.create(name, *args, options, &block)
        set_factory_default(name, obj, preserve)
      end

      def set_factory_default(name, obj, preserve_traits = nil)
        FactoryDefault.register(name, obj, preserve_traits)
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
        @store_preserve_traits = {}
        # default is false to retain backward compatibility
        @preserve_traits = false
      end

      def register(name, obj, preserve_traits = nil)
        unless FactoryDefault.preserve_traits
          @store_preserve_traits[name] ||= true if preserve_traits
        end
        store[name] = obj
      end

      def get(name, _traits = nil)
        store[name]
      end

      def exists?(name, traits = nil)
        if traits && !traits.empty?
          return false if FactoryDefault.preserve_traits || @store_preserve_traits[name]
        end
        store.key?(name)
      end

      def remove(name)
        store.delete(name)
      end

      def reset
        @store.clear
        @store_preserve_traits.clear
      end

      private

      attr_reader :store
    end
  end
end
