# frozen_string_literal: true

require "lint_roller"

module RuboCop
  module TestProf
    # A plugin that integrates TestProf with RuboCop's plugin system.
    class Plugin < LintRoller::Plugin
      def about
        LintRoller::About.new(
          name: "test-prof",
          version: ::TestProf::VERSION,
          homepage: "https://test-prof.evilmartians.io/misc/rubocop",
          description: "RuboCop plugin to help you write more performant tests."
        )
      end

      def supported?(context)
        context.engine == :rubocop
      end

      def rules(_context)
        LintRoller::Rules.new(
          type: :path,
          config_format: :rubocop,
          value: Pathname.new(__dir__).join("../../../config/default.yml")
        )
      end
    end
  end
end
