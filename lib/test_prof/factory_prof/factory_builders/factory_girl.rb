# frozen_string_literal: true

require "test_prof/factory_prof/factory_girl_patch"

module TestProf
  module FactoryProf
    module FactoryBuilders
      # implementation of #patch and #track methods
      # to provide unified interface for all factory-building gems
      class FactoryGirl
        # Monkey-patch FactoryGirl
        def self.patch
          TestProf.require 'factory_girl' do
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
