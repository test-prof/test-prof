# frozen_string_literal: true

require "prism"

module TestProf
  module RSpecStamp
    module Parser
      class Prism
        def parse(code)
          result = ::Prism.parse(code)
          return unless result.success?

          node = result.value.statements.body.first
          return unless node.is_a?(::Prism::CallNode)

          res = Result.new
          res.fname =
            if node.receiver
              "#{node.receiver.full_name}.#{node.name}"
            else
              node.name.name
            end

          args = node.arguments&.arguments
          return res if args.nil?

          rest =
            case (first = args.first).type
            when :string_node
              res.desc = first.content
              args[1..]
            when :constant_read_node, :constant_path_node
              res.desc_const = first.full_name
              args[1..]
            else
              args
            end

          rest.each do |arg|
            case arg.type
            when :symbol_node
              res.add_tag(arg.value.to_sym)
            when :keyword_hash_node
              arg.elements.each do |assoc|
                res.add_htag(
                  assoc.key.value.to_sym,
                  parse_htag_value(assoc.value)
                )
              end
            end
          end

          res
        end

        private

        def parse_htag_value(node)
          case node.type
          when :true_node
            true
          when :false_node
            false
          when :integer_node, :float_node
            node.value
          when :string_node
            node.unescaped
          when :symbol_node
            node.value.to_sym
          end
        end
      end
    end
  end
end
