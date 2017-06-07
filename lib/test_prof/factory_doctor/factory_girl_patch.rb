# frozen_string_literal: true

module TestProf
  module FactoryDoctor
    # Wrap #run method with FactoryDoctor tracking
    module FactoryGirlPatch
      def run(strategy = @strategy)
        FactoryDoctor.within_factory(strategy) { super }
      end
    end
  end
end
