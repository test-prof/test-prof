# frozen_string_literal: true

module TestProf
  module Utils # :nodoc:
    class << self
      # Verify that loaded gem has correct version
      def verify_gem_version(gem_name, at_least: nil, at_most: nil)
        raise ArgumentError, "Please, provide `at_least` or `at_most` argument" if
          at_least.nil? && at_most.nil?

        version = Gem.loaded_specs[gem_name].try(:version)
        return false if version.blank?

        supported_version?(version, at_least, at_most)
      end

      def supported_version?(gem_version, at_least, at_most)
        (at_least.nil? || Gem::Version.new(at_least) <= gem_version) &&
          (at_most.nil? || Gem::Version.new(at_most) >= gem_version)
      end
    end
  end
end
