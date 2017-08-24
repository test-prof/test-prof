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

    def let_it_be(identifier, reload: nil, &block)
      raise ArgumentError, "Block is required!" unless block_given?

      this = self

      if within_before_all?
        before(:all) do
          this.instance_variable_set(:"#{PREFIX}#{identifier}", this.instance_exec(&block))
        end
      else
        before_all do
          this.instance_variable_set(:"#{PREFIX}#{identifier}", this.instance_exec(&block))
        end
      end

      accessor =
        if reload
          -> { this.instance_variable_get(:"#{PREFIX}#{identifier}")&.reload }
        else
          -> { this.instance_variable_get(:"#{PREFIX}#{identifier}") }
        end

      define_singleton_method(identifier) { this.instance_variable_get(:"#{PREFIX}#{identifier}") }
      let(identifier, &accessor)
    end
  end
end

RSpec.configure do |config|
  config.extend TestProf::LetItBe
end
