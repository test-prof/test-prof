# frozen_string_literal: true

module TestProf
  module FactoryDefault # :nodoc: all
    module RunnerExt
      refine TestProf::FactoryBot::FactoryRunner do
        def name
          @name
        end
      end
    end

    using RunnerExt

    module StrategyExt
      def association(runner)
        return super unless FactoryDefault.exists?(runner.name)
        FactoryDefault.get(runner.name)
      end
    end
  end
end
