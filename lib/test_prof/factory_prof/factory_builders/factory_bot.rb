# frozen_string_literal: true

require "test_prof/factory_prof/factory_bot_patch"
require "test_prof/factory_bot"

module TestProf
  module FactoryProf
    module FactoryBuilders
      # implementation of #patch and #track methods
      # to provide unified interface for all factory-building gems
      class FactoryBot
        # FactoryBot 5.0 uses strategy classes for associations,
        # older versions and top-level invocations use Symbols
        using(Module.new do
          refine Symbol do
            def create?
              self == :create
            end
          end

          if defined?(::FactoryBot::Strategy::Create)
            refine Class do
              def create?
                self <= ::FactoryBot::Strategy::Create
              end
            end
          end
        end)

        # Monkey-patch FactoryBot / FactoryGirl
        def self.patch
          TestProf::FactoryBot::FactoryRunner.prepend(FactoryBotPatch) if
            defined? TestProf::FactoryBot
        end

        def self.track(strategy, factory, &block)
          return yield unless strategy.create?
          FactoryProf.track(factory, &block)
        end
      end
    end
  end
end
