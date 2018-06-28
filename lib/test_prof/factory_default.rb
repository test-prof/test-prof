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
        preserve = options.delete(:preserve_traits)

        obj = TestProf::FactoryBot.create(name, *args, options, &block)
        set_factory_default(name, obj, preserve_traits: preserve)
      end

      def set_factory_default(name, obj, preserve_traits: nil)
        FactoryDefault.register(name, obj, preserve_traits: preserve_traits)
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
        # default is false to retain backward compatibility
        @preserve_traits = false
      end

      def register(name, obj, **options)
        options[:preserve_traits] = true if FactoryDefault.preserve_traits
        store[name] = { object: obj, **options }
        obj
      end

      def get(name, traits = nil)
        record = store[name]
        return unless record

        if traits && !traits.empty?
          return nil if FactoryDefault.preserve_traits || record[:preserve_traits]
        end
        record[:object]
      end

      def exists?(name, traits = nil)
        get(name, traits) && true || false
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
