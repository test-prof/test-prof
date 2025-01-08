# frozen_string_literal: true

module TestProf
  # YJIT checker.
  #
  # Complains about YJIT being turned on, as it is designed for production
  # environments and it is known to slowdown test suites.
  #
  # It is currently not possible to programmatically disable YJIT, only to
  # enable it. If once it becomes possible, we should disable it by default.
  #
  # @see https://github.com/rails/rails/pull/53746
  module YJIT
    class << self
      include Logging

      def check!
        return unless enabled?

        complain if defined?(RubyVM) && defined?(RubyVM::YJIT) && RubyVM::YJIT.enabled?
      end

      private

      def complain
        log(:warn, <<~MSG)
          YJIT is enabled. It is designed for production environments and is known to slow down test suites. You should disable it for better test performance.
        MSG

        if yjit_via_env?
          log(:warn, <<~MSG)
            It looks like YJIT is enabled via an environment variable, `RUBY_YJIT_ENABLE`. Consider removing it.
          MSG
        else
          log(:warn, <<~MSG)
            Check your code for `RubyVM::YJIT.enable` call, or your scripts for the `--yjit` flag.
          MSG
        end

        log(:warn, <<~MSG)

          If you wish to disable this warning, run with `YJIT_PROF=0`.

        MSG
      end

      def enabled?
        !ENV.key?("YJIT_PROF") || !%w[0 false].include?(ENV["YJIT_PROF"])
      end

      def yjit_via_env?
        ENV.key?("RUBY_YJIT_ENABLE")
      end
    end
  end
end

TestProf::YJIT.check!
