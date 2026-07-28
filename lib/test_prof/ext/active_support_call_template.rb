# frozen_string_literal: true

module TestProf
  module Ext
    module ActiveSupportCallTemplate
      module BuildOverride
        def build(filter, callback)
          template = super
          return template unless filter.equal?(callback.instance_variable_get(:@filter))

          kind, name = callback.kind, callback.name
          original = template.method(:make_lambda)
          template.define_singleton_method(:make_lambda) do
            TestProf::Filters::CallbackInvocation.new(original.call, kind, name, filter)
          end
          template
        end
      end
    end
  end
end

module TestProf
  module Filters
    class CallbackInvocation
      attr_reader :original, :kind, :name, :filter

      def initialize(original, kind, name, filter)
        @original = original
        @kind = kind
        @name = name
        @filter = filter
      end

      def call(target, value, &block)
        @original.call(target, value, &block)
      end
    end
  end
end

if defined?(::ActiveSupport::Callbacks::CallTemplate)
  ActiveSupport::Callbacks::CallTemplate.singleton_class.prepend(
    TestProf::Ext::ActiveSupportCallTemplate::BuildOverride
  )
else
  TestProf.log(
    :error,
    <<~MSG
      Failed to activate "callback.run" profiler: ActiveSupport::Callbacks::CallTemplate is not defined.

      Make sure `active_support/callbacks` is loaded and you're using Rails >= 5.1
      (earlier versions have different callbacks internals and are not supported).
    MSG
  )
end
