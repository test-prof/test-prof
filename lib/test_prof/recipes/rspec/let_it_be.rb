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
    end

    class << self
      def config
        @config ||= Configuration.new
      end

      def configure
        yield config
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

    def define_let_it_be_methods(identifier, reload: false, refind: false)
      let_accessor = -> { instance_variable_get(:"#{PREFIX}#{identifier}") }

      if reload
        let_accessor = lambda do
          record = instance_variable_get(:"#{PREFIX}#{identifier}")
          next unless record.is_a?(::ActiveRecord::Base)
          record.reload
        end
      end

      if refind
        let_accessor = lambda do
          record = instance_variable_get(:"#{PREFIX}#{identifier}")
          next unless record.is_a?(::ActiveRecord::Base)

          record.class.find(record.send(record.class.primary_key))
        end
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

RSpec::Core::ExampleGroup.extend TestProf::LetItBe
