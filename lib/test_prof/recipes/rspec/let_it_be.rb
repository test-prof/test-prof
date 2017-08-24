# frozen_string_literal: true

require_relative "./before_all"

module TestProf
  # Just like `let`, but persist the result for the whole group.
  # NOTE: Experimental and magical, for more control use `before_all`.
  module LetItBe
    # Use uniq prefix for instance variables to avoid collisions
    # We want to use the power of Ruby's unicode support)
    # And we love cats!)
    PREFIX = "@😸"

    def let_it_be(identifier, reload: false, refind: false, &block)
      raise ArgumentError, "Block is required!" unless block_given?

      this = self

      initializer = proc do
        this.instance_variable_set(:"#{PREFIX}#{identifier}", this.instance_exec(&block))
      end

      if within_before_all?
        before(:all, &initializer)
      else
        before_all(&initializer)
      end

      let_accessor = accessor = -> { this.instance_variable_get(:"#{PREFIX}#{identifier}") }

      let_accessor = -> { this.instance_variable_get(:"#{PREFIX}#{identifier}")&.reload } if reload

      if refind
        let_accessor = lambda do
          record = this.instance_variable_get(:"#{PREFIX}#{identifier}")
          next unless record.is_a?(::ActiveRecord::Base)

          record.class.find(record.send(record.class.primary_key))
        end
      end

      define_singleton_method(identifier, &accessor)
      let(identifier, &let_accessor)
    end
  end
end

RSpec.configure do |config|
  config.extend TestProf::LetItBe
end
