# frozen_string_literal: true

require "ripper"

module TestProf
  module RSpecStamp
    # Parse examples headers
    module Parser
      # Contains the result of parsing
      class Result
        attr_accessor :fname, :desc
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
          @tags.delete(tag) if @tags
          @htags.delete_if { |(k, _v)| k == tag } if @htags
        end
      end

      class << self
        # rubocop: disable Metrics/CyclomaticComplexity
        def parse(code)
          sexp = Ripper.sexp(code)
          return unless sexp

          # sexp has the following format:
          # [:program,
          #   [
          #     [
          #       :command,
          #       [:@ident, "it", [1, 0]],
          #       [:args_add_block, [ ... ]]
          #     ]
          #   ]
          # ]
          #
          # or
          #
          # [:program,
          #   [
          #     [
          #       :vcall,
          #       [:@ident, "it", [1, 0]]
          #     ]
          #   ]
          # ]
          res = Result.new

          fcall = sexp[1][0][1]
          fcall = fcall[1] if fcall.first == :fcall
          res.fname = fcall[1]

          args_block = sexp[1][0][2]

          return res if args_block.nil?

          args_block = args_block[1] if args_block.first == :arg_paren

          args = args_block[1]

          if args.first.first == :string_literal
            res.desc = parse_literal(args.shift)
          end

          parse_arg(res, args.shift) until args.empty?

          res
        end
        # rubocop: enable Metrics/CyclomaticComplexity

        private

        def parse_arg(res, arg)
          if arg.first == :symbol_literal
            res.add_tag parse_literal(arg)
          elsif arg.first == :bare_assoc_hash
            parse_hash(res, arg[1])
          end
        end

        def parse_hash(res, hash_arg)
          hash_arg.each do |(_, label, val)|
            res.add_htag label[1][0..-2].to_sym, parse_literal(val)
          end
        end

        # Expr of the form:
        #  [:string_literal, [:string_content, [:@tstring_content, "is", [1, 4]]]]
        def parse_literal(expr)
          val = expr[1][1][1]
          val = val.to_sym if expr[0] == :symbol_literal ||
                              expr[0] == :assoc_new
          val
        end
      end
    end
  end
end
