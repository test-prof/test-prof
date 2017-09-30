# frozen_string_literal: true

module TestProf
  module FactoryProf
    module FactoryBuilders
      class Fabrication
        # Monkey-patch Fabrication
        def self.patch
          TestProf.require 'fabrication', ""
          if defined?(::Fabrication)
            ::Fabricate.singleton_class.prepend(FabricationPatch)
          end
        end

        def self.track(factory, &block)
          FactoryProf.track(factory, &block)
        end
      end
    end
  end
end
