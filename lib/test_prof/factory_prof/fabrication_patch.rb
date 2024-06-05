# frozen_string_literal: true

module TestProf
  module FactoryProf
    # Wrap #run method with FactoryProf tracking
    module FabricationPatch
      def create(name, overrides = {})
        variation = ""

        if FactoryProf.config.include_variations && !overrides.empty?
          variation += overrides.keys.sort.to_s.gsub(/[\\":]/, "")
        end

        FactoryBuilders::Fabrication.track(name, variation: variation.to_sym) { super }
      end
    end
  end
end
