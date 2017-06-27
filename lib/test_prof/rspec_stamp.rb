# frozen_string_literal: true

require "test_prof/logging"
require "test_prof/rspec_stamp/parser"

module TestProf
  # Mark RSpec examples with provided tags
  module RSpecStamp
    EXAMPLE_RXP = /(\s*)(\w+\s*(?:.*)\s*)(do|{)/

    # RSpecStamp configuration
    class Configuration
      attr_accessor :ignore_files, :dry_run, :tags

      def initialize
        @ignore_files = [%r{spec/support}]
        @dry_run = ENV['RSTAMP_DRY_RUN'] == '1'
        self.tags = ENV['RSTAMP']
      end

      def dry_run?
        @dry_run == true
      end

      def tags=(val)
        @tags = if val.is_a?(String)
                  parse_tags(val)
                else
                  val
                end
      end

      private

      def parse_tags(str)
        str.split(/\s*,\s*/).each_with_object([]) do |tag, acc|
          k, v = tag.split(":")
          acc << if v.nil?
                   k.to_sym
                 else
                   Hash[k.to_sym, v.to_sym]
                 end
        end
      end
    end

    class << self
      include TestProf::Logging

      def config
        @config ||= Configuration.new
      end

      def configure
        yield config
      end

      # Accepts source code (as array of lines),
      # line numbers (of example to apply tags)
      # and an array of tags.
      def apply_tags(code, lines, tags)
        failed = 0

        lines.each do |line|
          unless stamp_example(code[line - 1], tags)
            failed += 1
            log :warn, "Failed to stamp: #{code[line - 1]}"
          end
        end
        failed
      end

      private

      # rubocop: disable Metrics/CyclomaticComplexity
      # rubocop: disable Metrics/PerceivedComplexity
      def stamp_example(example, tags)
        matches = example.match(EXAMPLE_RXP)
        return false unless matches

        code = matches[2]
        block = matches[3]

        parsed = Parser.parse(code)
        return false unless parsed

        parsed.desc ||= 'works'

        tags.each do |t|
          if t.is_a?(Hash)
            t.keys.each { |k| parsed.add_htag(k, t[k]) }
          else
            parsed.add_tag(t)
          end
        end

        need_parens = block == "{"

        tags_str = parsed.tags.map { |t| t.is_a?(Symbol) ? ":#{t}" : t }.join(", ") unless
          parsed.tags.nil?

        unless parsed.htags.nil?
          htags_str = parsed.htags.map do |(k, v)|
            vstr = v.is_a?(Symbol) ? ":#{v}" : quote(v)

            "#{k}: #{vstr}"
          end
        end

        replacement = "\\1#{parsed.fname}#{need_parens ? '(' : ' '}"\
                      "#{[quote(parsed.desc), tags_str, htags_str].compact.join(', ')}"\
                      "#{need_parens ? ') ' : ' '}\\3"

        if config.dry_run?
          log :info, "Patched: #{example.sub(EXAMPLE_RXP, replacement)}"
        else
          example.sub!(EXAMPLE_RXP, replacement)
        end
        true
      end
      # rubocop: enable Metrics/CyclomaticComplexity
      # rubocop: enable Metrics/PerceivedComplexity

      def quote(str)
        if str.include?("'")
          "\"#{str}\""
        else
          "'#{str}'"
        end
      end
    end
  end
end

require "test_prof/rspec_stamp/rspec" if defined?(RSpec)
