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
      end
    end

    using RunnerExt

    module StrategyExt
      def association(runner)
        FactoryDefault.get(runner.name, runner.traits) || super
      end
    end
  end
end
