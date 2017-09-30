# frozen_string_literal: true

module TestProf
  module FactoryProf
    module FactoryBuilders
      class FactoryGirl
        # Monkey-patch FactoryGirl
        def self.patch
          if defined?(::FactoryGirl)
            ::FactoryGirl::FactoryRunner.prepend(FactoryGirlPatch)
          end
        end

        def self.track(strategy, factory, &block)
          return yield unless strategy == :create
          FactoryProf.track(factory, &block)
        end
      end
    end
  end
end
