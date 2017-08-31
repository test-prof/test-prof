# frozen_string_literal: true

require_relative "./before_all"

module TestProf
  # Just like `let`, but persist the result for the whole group.
  # NOTE: Experimental and magical, for more control use `before_all`.
  module LetItBe
    class << self
      def module_for(group)
        modules.fetch(group) do
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
    PREFIX = RUBY_ENGINE == 'jruby' ? "@__jruby_is_not_cat_friendly__".freeze : "@😸".freeze

    def let_it_be(identifier, **options, &block)
      initializer = proc do
        instance_variable_set(:"#{PREFIX}#{identifier}", instance_exec(&block))
      end

      if within_before_all?
        before(:all, &initializer)
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
          if @__inspect_output =~ /\(:context\)/
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

RSpec.configure do |config|
  config.extend TestProf::LetItBe
end
