# frozen_string_literal: true

module TestProf
  module FactoryDefault # :nodoc: all
    module RunnerExt
      refine TestProf::FactoryBot::FactoryRunner do
        def name
          @name
        end

        def traits
          @traits
        end

        def overrides
          @overrides
        end
      end
    end

    using RunnerExt

    module StrategyExt
      def association(runner)
        return super unless FactoryDefault.exists?(runner.name, runner.traits)
        FactoryDefault.get(runner.name, runner.traits)
      end
    end
  end
end
