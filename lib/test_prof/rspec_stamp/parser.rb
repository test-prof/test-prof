# frozen_string_literal: true

module TestProf
  module RSpecStamp
    # Parse examples headers
    module Parser
      # Contains the result of parsing
      class Result
        attr_accessor :fname, :desc, :desc_const
        attr_reader :tags, :htags

        def add_tag(v)
          @tags ||= []
          @tags << v
        end

        def add_htag(k, v)
          @htags ||= []
          @htags << [k, v]
        end

        def remove_tag(tag)
          @tags&.delete(tag)
          @htags&.delete_if { |(k, _v)| k == tag }
        end
      end

      instance =
        begin
          require_relative "parser/prism"
          self::Prism.new
        rescue LoadError
          require_relative "parser/ripper"
          self::Ripper.new
        end

      define_singleton_method(:parse) { |code| instance.parse(code) }
    end
  end
end
