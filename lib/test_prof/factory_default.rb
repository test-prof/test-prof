# frozen_string_literal: true

require "test_prof"
require "test_prof/factory_bot"
require "test_prof/factory_default/factory_bot_patch"

module TestProf
  # FactoryDefault allows use to re-use associated objects
  # in factories implicilty
  module FactoryDefault
    module DefaultSyntax # :nodoc:
      def create_default(name, *args, &block)
        options = args.extract_options!
        default_options = {}
        default_options[:preserve_traits] = options.delete(:preserve_traits) if options.key?(:preserve_traits)
        default_options[:preserve_attributes] = options.delete(:preserve_attributes) if options.key?(:preserve_attributes)

        obj = TestProf::FactoryBot.create(name, *args, options, &block)
        set_factory_default(name, obj, **default_options)
      end

      def set_factory_default(name, obj, preserve_traits: FactoryDefault.preserve_traits, preserve_attributes: FactoryDefault.preserve_attributes)
        FactoryDefault.register(
          name, obj,
          preserve_traits: preserve_traits,
          preserve_attributes: preserve_attributes
        )
      end

      def skip_factory_default(&block)
        FactoryDefault.disable!(&block)
      end
    end

    class << self
      attr_accessor :preserve_traits, :preserve_attributes

      def init
        TestProf::FactoryBot::Syntax::Methods.include DefaultSyntax
        TestProf::FactoryBot.extend DefaultSyntax
        TestProf::FactoryBot::Strategy::Create.prepend StrategyExt
        TestProf::FactoryBot::Strategy::Build.prepend StrategyExt
        TestProf::FactoryBot::Strategy::Stub.prepend StrategyExt

        @enabled = true
        # default is false to retain backward compatibility
        @preserve_traits = false
        @preserve_attributes = false
      end

      def register(name, obj, **options)
        store[name] = {object: obj, **options}
        obj
      end

      def get(name, traits = nil, overrides = nil)
        return unless enabled?

        record = store[name]
        return unless record

        if traits && !traits.empty?
          return if record[:preserve_traits]
        end

        object = record[:object]

        if overrides && !overrides.empty? && record[:preserve_attributes]
          overrides.each do |name, value|
            return unless object.respond_to?(name) # rubocop:disable Lint/NonLocalExitFromIterator
            return if object.public_send(name) != value # rubocop:disable Lint/NonLocalExitFromIterator
          end
        end

        object
      end

      def remove(name)
        store.delete(name)
      end

      def reset
        store.clear
      end

      def enabled?
        @enabled
      end

      def enable!
        was_enabled = @enabled
        @enabled = true
        return unless block_given?
        yield
      ensure
        @enabled = was_enabled
      end

      def disable!
        was_enabled = @enabled
        @enabled = false
        return unless block_given?
        yield
      ensure
        @enabled = was_enabled
      end

      private

      def store
        Thread.current[:testprof_factory_store] ||= {}
      end
    end
  end
end
