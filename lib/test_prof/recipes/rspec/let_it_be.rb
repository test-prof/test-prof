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

    def self.define_let_it_be_alias(name, **default_args)
      define_method(name) do |identifier, **options, &blk|
        let_it_be(identifier, **default_args.merge(options), &blk)
      end
    end

    # Some of the examples might (unwillingly, or deliberately) update
    # model attributes.
    # Unwillingly - if the underlying code under test modifies models, e.g.
    # modifies `updated_at` attribute.
    # Deliberately - if models are updated in `before` hooks or examples
    # themselves instead of creating models in a proper state initially.
    #
    # It doesn't really matter if the database is modified or not since
    # it's rolled back to a pristine state.
    # However, since models created with `let_it_be` are shared between
    # the examples, non-reloaded changes to models remain and leak between
    # examples.
    #
    # This leads to unpredictable failures, and in worst case scenario
    # examples that implicitly depend on other examples.
    #
    # Root cause is hard to track down, especially with random example
    # execution order. A spec might fail with --seed 1001, but pass with
    # 1002 & 1003.
    #
    # With many shared models between many examples, it's also hard to
    # track down the example and exact place in the code that modifies
    # the model. Even though the fix is trivial - to add set `refind` or
    # `reload` options, it's rarely obvious where it should be set
    # exactly.
    def let_it_be(identifier, **options, &block)
      freeze = options.fetch(:freeze, !(options[:reload] || options[:refind]))
      initializer = build_initializer(identifier, freeze, &block)

      if within_before_all?
        within_before_all(&initializer)
      else
        before_all(&initializer)
      end

      define_let_it_be_methods(identifier, **options.except(:freeze))
      handle_frozen_hash_error
    end

    FROZEN_HASH_REGEX = /can't modify frozen Hash/
    FROZEN_HASH_HINT = "\nIf you are using `let_it_be`, you may want to pass `reload: true` option to it."

    # Exception needs to be handled both here and in `handle_frozen_hash_error`
    # because if it is raised in before_all it isn't caught in `after` block and
    # if it's inside the example it isn't raised so it has to be handled in `after`.
    def build_initializer(identifier, freeze, &block)
      proc do
        begin
          record = instance_exec(&block)
          if freeze
            record.freeze
            record.each(&:freeze) if record.respond_to?(:each)
          end

          instance_variable_set(:"#{TestProf::LetItBe::PREFIX}#{identifier}", record)
        rescue => e
          raise e unless e.message.match?(FROZEN_HASH_REGEX)
          e.message << FROZEN_HASH_HINT
          raise e
        end
      end
    end

    def handle_frozen_hash_error
      # Prevent `after` block from being defined several times
      return if metadata[:"#{PREFIX}frozen_hash_handled"]

      prepend_after do |example|
        if example.exception&.message&.match?(FROZEN_HASH_REGEX)
          example.exception.message << FROZEN_HASH_HINT
        end
      end

      metadata[:"#{PREFIX}frozen_hash_handled"] = true
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
