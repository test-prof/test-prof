# frozen_string_literal: true

module TestProf
  module FactoryDefault # :nodoc: all
    module FabricationPatch
      module DefaultExt
        def create_default(name, overrides = {}, &block)
          obj = ::Fabricate.create(name, overrides, &block)
          set_fabricate_default(name, obj)
        end

        def set_fabricate_default(name, obj, **opts)
          FactoryDefault.register(
            name, obj,
            preserve_attributes: FactoryDefault.config.preserve_attributes,
            preserve_traits: FactoryDefault.config.preserve_traits,
            **opts
          )
        end

        def get_fabricate_default(name, **overrides)
          FactoryDefault.get(name, nil, overrides, skip_stats: true)
        end

        def skip_fabricate_default(&block)
          FactoryDefault.disable!(&block)
        end

        def create(name, overrides = {}, &block)
          self.fabrication_depth += 1
          # We do not support defaults for objects created with attribute blocks
          return super if block

          return super if fabrication_depth < 2

          FactoryDefault.get(name, nil, overrides, **{}) ||
            FactoryDefault.profiler.instrument(name, nil, overrides) { super }
        ensure
          self.fabrication_depth -= 1
        end

        private

        def fabrication_depth
          Thread.current[:_fab_depth_] ||= 0
        end

        def fabrication_depth=(value)
          Thread.current[:_fab_depth_] = value
        end
      end

      def self.patch
        TestProf.require "fabrication" do
          ::Fabricate.singleton_class.prepend(DefaultExt)
        end
      end
    end
  end
end
