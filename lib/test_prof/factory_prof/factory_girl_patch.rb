# frozen_string_literal: true

module TestProf
  module FactoryProf
    # Wrap #run method with FactoryProf tracking
    module FactoryGirlPatch
      def run(strategy = @strategy)
        FactoryBuilders::FactoryGirl.track(strategy, @name) { super }
      end
    end
  end
end
