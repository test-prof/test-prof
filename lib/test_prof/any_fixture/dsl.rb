# frozen_string_literal: true

if defined?(::ActiveRecord::Base)
  require "test_prof/ext/active_record_refind"
  using TestProf::Ext::ActiveRecordRefind
end

module TestProf
  module AnyFixture
    # Adds "global" `fixture`, `before_fixtures_reset` and `after_fixtures_reset` methods (through refinement)
    module DSL
      # Refine object, 'cause refining modules (Kernel) is vulnerable to prepend:
      # - https://bugs.ruby-lang.org/issues/13446
      # - Rails added `Kernel.prepend` in 6.1: https://github.com/rails/rails/commit/3124007bd674dcdc9c3b5c6b2964dfb7a1a0733c
      refine ::Object do
        def fixture(id, &block)
          id = :"#{id}"
          record = ::TestProf::AnyFixture.cached(id)

          return ::TestProf::AnyFixture.register(id, &block) unless record

          return record.refind if record.is_a?(::ActiveRecord::Base)

          if record.respond_to?(:to_ary)
            return record.map do |rec|
              rec.is_a?(::ActiveRecord::Base) ? rec.refind : rec
            end
          end

          record
        end

        def before_fixtures_reset(&block)
          ::TestProf::AnyFixture.before_fixtures_reset(&block)
        end

        def after_fixtures_reset(&block)
          ::TestProf::AnyFixture.after_fixtures_reset(&block)
        end
      end
    end
  end
end
