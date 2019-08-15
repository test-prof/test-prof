# frozen_string_literal: true

require "test_prof"
require_relative "./before_all"

module TestProf
  # Just like `let`, but persist the result for the whole group.
  # NOTE: Experimental and magical, for more control use `before_all`.
  module LetItBe
    class Configuration
      # Define an alias for `let_it_be` with the predefined options:
      #
      #   TestProf::LetItBe.configure do |config|
      #     config.alias_to :let_it_be_reloaded, reload: true
      #   end
      def alias_to(name, **default_args)
        LetItBe.define_let_it_be_alias(name, **default_args)
      end

      def register_modifier(key, &block)
        raise ArgumentError, "Modifier #{key} is already defined for let_it_be" if LetItBe.modifiers.key?(key)

        LetItBe.modifiers[key] = block
      end
    end

    class << self
      def config
        @config ||= Configuration.new
      end

      def configure
        yield config
      end

      def modifiers
        @modifiers ||= {}
      end

      def wrap_with_modifiers(mods, &block)
        validate_modifiers! mods

        return block if mods.empty?

        -> {
          instance_eval(&block).then do |record|
            mods.inject(record) do |rec, (k, v)|
              LetItBe.modifiers.fetch(k).call(rec, v)
            end
          end
        }
      end

      def module_for(group)
        modules[group] ||= begin
          Module.new.tap { |mod| group.prepend(mod) }
        end
      end

      private

      def modules
        @modules ||= {}
      end

      def validate_modifiers!(mods)
        unknown = mods.keys - modifiers.keys
        return if unknown.empty?

        raise ArgumentError, "Unknown let_it_be modifiers were used: #{unknown.join(", ")}. " \
                             "Available modifiers are: #{modifiers.keys.join(", ")}"
      end
    end
    # Use uniq prefix for instance variables to avoid collisions
    # We want to use the power of Ruby's unicode support)
    # And we love cats!)
    PREFIX = RUBY_ENGINE == "jruby" ? "@__jruby_is_not_cat_friendly__" : "@😸"

    def self.define_let_it_be_alias(name, **default_args)
      define_method(name) do |identifier, **options, &blk|
        let_it_be(identifier, default_args.merge(options), &blk)
      end
    end

    def let_it_be(identifier, **options, &block)
      initializer = proc do
        instance_variable_set(:"#{PREFIX}#{identifier}", instance_exec(&block))
      end

      if within_before_all?
        within_before_all(&initializer)
      else
        before_all(&initializer)
      end

      define_let_it_be_methods(identifier, **options)
    end

    def define_let_it_be_methods(identifier, **modifiers)
      let_accessor = LetItBe.wrap_with_modifiers(modifiers) do
        instance_variable_get(:"#{PREFIX}#{identifier}")
      end

      LetItBe.module_for(self).module_eval do
        define_method(identifier) do
          # Trying to detect the context (couldn't find other way so far)
          if /\(:context\)/.match?(@__inspect_output)
            instance_variable_get(:"#{PREFIX}#{identifier}")
          else
            # Fallback to let definition
            super()
          end
        end
      end

      let(identifier, &let_accessor)
    end
  end
end

require "test_prof/ext/active_record_refind"
using TestProf::Ext::ActiveRecordRefind

TestProf::LetItBe.configure do |config|
  config.register_modifier :reload do |record, val|
    next record unless val
    next record unless record.is_a?(::ActiveRecord::Base)
    record.reload
  end

  config.register_modifier :refind do |record, val|
    next record unless val
    next record unless record.is_a?(::ActiveRecord::Base)
    record.refind
  end
end

RSpec::Core::ExampleGroup.extend TestProf::LetItBe
