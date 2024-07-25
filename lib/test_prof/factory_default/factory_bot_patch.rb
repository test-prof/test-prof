# frozen_string_literal: true

require "test_prof/factory_bot"

module TestProf
  module FactoryDefault # :nodoc: all
    module FactoryBotPatch
      if defined?(TestProf::FactoryBot::FactoryRunner)
        module RunnerExt
          refine TestProf::FactoryBot::FactoryRunner do
            attr_reader :name, :traits, :overrides
          end
        end

        using RunnerExt
      end

      module StrategyExt
        def association(runner)
          FactoryDefault.get(runner.name, runner.traits, runner.overrides, **{}) ||
            FactoryDefault.profiler.instrument(runner.name, runner.traits, runner.overrides) { super }
        end
      end

      module SyntaxExt
        def create_default(name, *args, &block)
          options = args.extract_options!
          default_options = {}
          default_options[:preserve_traits] = options.delete(:preserve_traits) if options.key?(:preserve_traits)
          default_options[:preserve_attributes] = options.delete(:preserve_attributes) if options.key?(:preserve_attributes)

          obj = TestProf::FactoryBot.create(name, *args, options, &block)

          # Factory with traits
          name = [name, *args] if args.any?

          set_factory_default(name, obj, **default_options)
        end

        def set_factory_default(*name, obj, preserve_traits: FactoryDefault.config.preserve_traits, preserve_attributes: FactoryDefault.config.preserve_attributes, **other)
          name = name.first if name.size == 1
          FactoryDefault.register(
            name, obj,
            preserve_traits: preserve_traits,
            preserve_attributes: preserve_attributes,
            **other
          )
        end

        def get_factory_default(name, *traits, **overrides)
          FactoryDefault.get(name, traits, overrides, skip_stats: true)
        end

        def skip_factory_default(&block)
          FactoryDefault.disable!(&block)
        end
      end

      def self.patch
        return unless defined?(TestProf::FactoryBot)

        TestProf::FactoryBot::Syntax::Methods.include SyntaxExt
        TestProf::FactoryBot.extend SyntaxExt
        TestProf::FactoryBot::Strategy::Create.prepend StrategyExt
        TestProf::FactoryBot::Strategy::Build.prepend StrategyExt
        TestProf::FactoryBot::Strategy::Stub.prepend StrategyExt
      end
    end
  end
end
