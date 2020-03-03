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
        return block if mods.empty?

        validate_modifiers! mods

        -> {
          record = instance_eval(&block)
          mods.inject(record) do |rec, (k, v)|
            LetItBe.modifiers.fetch(k).call(rec, v)
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

    FROZEN_HASH_HINT = "\nIf you are using `let_it_be`, you may want to pass `reload: true` option to it."

    def self.define_let_it_be_alias(name, **default_args)
      define_method(name) do |identifier, **options, &blk|
        let_it_be(identifier, **default_args.merge(options), &blk)
      end
    end

    def let_it_be(identifier, **options, &block)
      freeze = options.fetch(:freeze, !(options[:reload] || options[:refind]))

      initializer = build_let_it_be_initializer(identifier, freeze, &block)
      before_all(&initializer)

      define_freezing_hooks if freeze && !metadata[:let_it_be_defrost]

      define_let_it_be_methods(identifier, **options.except(:freeze))
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

    def define_freezing_hooks
      # Prevent hooks from being defined several times
      return if instance_variable_get(:"#{PREFIX}hooks_defined")

      before(:all) do
        let_it_be_objects = instance_variable_get(:"#{TestProf::LetItBe::PREFIX}let_it_be_objects")

        let_it_be_objects.each { |object| Freezer.deep_freeze(object) }
      end

      instance_variable_set(:"#{PREFIX}hooks_defined", true)
    end

    # Exception needs to be handled both here and in `handle_frozen_hash_error`
    # because if it is raised in before_all it isn't caught in `after` block and
    # if it's inside the example it isn't raised so it has to be handled in `after`.
    def build_let_it_be_initializer(identifier, freeze, &block)
      proc do
        begin
          record = instance_exec(&block)
          if freeze
            # FIXME: When models and their associations are defined with different
            # options, e.g. `reload: true` and without it, the ones that are not
            # supposed to be frozen will still be frozen here. Add those with
            # `reload: true`/`refind: true`/`freeze: false` to ignore list.
            let_it_be_objects = instance_variable_get(:"#{TestProf::LetItBe::PREFIX}let_it_be_objects")
            let_it_be_objects ||= instance_variable_set(:"#{TestProf::LetItBe::PREFIX}let_it_be_objects", [])
            let_it_be_objects << record
          end

          instance_variable_set(:"#{TestProf::LetItBe::PREFIX}#{identifier}", record)
        rescue => e
          e.message << FROZEN_HASH_HINT if e.message.match?(/can't modify frozen Hash/)
          raise e
        end
      end
    end

    module Freezer
      # Rerucsively freezes the object to detect modifications.
      def self.deep_freeze(record)
        return if record.frozen?

        record.freeze

        return record.each { |rec| deep_freeze(rec) } if record.respond_to?(:each)

        # Freeze associations as well.
        #
        # NOTE: `reload` statements in test or production code will cause
        # a `FrozenError`. In case the use of `reload` cannot be avoided, use
        # `reload: true` in `let_it_be` declaration.
        return unless record.is_a?(::ActiveRecord::Base)

        record.class.reflections.keys.each do |reflection|
          # But only if they are already loaded. If not yet loaded, they weren't
          # created by factories, and it's ok to mutate them.
          next unless association_cached?(record, reflection.to_sym)

          target = record.association(reflection.to_sym).target
          if target.is_a?(::ActiveRecord::Base) || target.is_a?(Array)
            deep_freeze(target)
          end
        end
      end

      if ActiveRecord::VERSION::MAJOR >= 5
        def self.association_cached?(record, reflection)
          record.association_cached?(reflection)
        end
      else
        def self.association_cached?(record, reflection)
          record.association_cache[reflection]
        end
      end
    end
  end
end

if defined?(::ActiveRecord)
  require "test_prof/ext/active_record_refind"
  using TestProf::Ext::ActiveRecordRefind

  TestProf::LetItBe.configure do |config|
    config.register_modifier :reload do |record, val|
      next record unless val
      next record.reload if record.is_a?(::ActiveRecord::Base)

      if record.respond_to?(:map)
        next record.map do |rec|
          rec.is_a?(::ActiveRecord::Base) ? rec.reload : rec
        end
      end
      record
    end

    config.register_modifier :refind do |record, val|
      next record unless val
      next record.refind if record.is_a?(::ActiveRecord::Base)

      if record.respond_to?(:map)
        next record.map do |rec|
          rec.is_a?(::ActiveRecord::Base) ? rec.refind : rec
        end
      end
      record
    end
  end
end

RSpec::Core::ExampleGroup.extend TestProf::LetItBe
RSpec.configure do |config|
  config.after(:example) do |example|
    if example.exception&.message&.match?(/can't modify frozen Hash/)
      example.exception.message << TestProf::LetItBe::FROZEN_HASH_HINT
    end
  end
end
