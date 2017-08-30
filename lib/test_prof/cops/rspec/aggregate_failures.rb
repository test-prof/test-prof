# frozen_string_literal: true

require 'rubocop'

module RuboCop
  module Cop
    module RSpec
      # Rejects and auto-corrects the usage of one-liners examples in favour of
      # :aggregate_failures feature.
      #
      # Example:
      #
      #  # bad
      #  it { is_expected.to be_success }
      #  it { is_expected.to have_header('X-TOTAL-PAGES', 10) }
      #  it { is_expected.to have_header('X-NEXT-PAGE', 2) }
      #
      #  # good
      #  it "returns the second page", :aggregate_failures do
      #    is_expected.to be_success
      #    is_expected.to have_header('X-TOTAL-PAGES', 10)
      #    is_expected.to have_header('X-NEXT-PAGE', 2)
      #  end
      #
      class AggregateFailures < RuboCop::Cop::Cop
        # From https://github.com/backus/rubocop-rspec/blob/master/lib/rubocop/rspec/language.rb
        GROUP_BLOCKS = %i[
          describe context feature example_group
          xdescribe xcontext xfeature
          fdescribe fcontext ffeature
        ].freeze

        EXAMPLE_BLOCKS = %i[
          it specify example scenario its
          fit fspecify fexample fscenario focus
          xit xspecify xexample xscenario ski
          pending
        ].freeze

        def on_block(node)
          method, _args, body = *node
          return unless body && body.begin_type?

          _receiver, method_name, _object = *method
          return unless GROUP_BLOCKS.include?(method_name)

          return if check_node(body)

          add_offense(
            node,
            :expression,
            'Use :aggregate_failures instead of several one-liners.'
          )
        end

        def autocorrect(node)
          _method, _args, body = *node
          iter = body.children.each

          first_example = loop do
            child = iter.next
            break child if oneliner?(child)
          end

          base_indent = " " * first_example.source_range.column

          replacements = [
            header_from(first_example),
            body_from(first_example, base_indent)
          ]

          last_example = nil

          loop do
            child = iter.next
            break unless oneliner?(child)
            last_example = child
            replacements << body_from(child, base_indent)
          end

          replacements << "#{base_indent}end"

          range = first_example.source_range.begin.join(
            last_example.source_range.end
          )

          replacement = replacements.join("\n")

          lambda do |corrector|
            corrector.replace(range, replacement)
          end
        end

        private

        def check_node(node)
          offenders = 0

          node.children.each do |child|
            if oneliner?(child)
              offenders += 1
            elsif example_node?(child)
              break if offenders > 1
              offenders = 0
            end
          end

          offenders < 2
        end

        def oneliner?(node)
          node && node.block_type? &&
            (node.source.lines.size == 1) &&
            example_node?(node)
        end

        def example_node?(node)
          method, _args, _body = *node
          _receiver, method_name, _object = *method
          EXAMPLE_BLOCKS.include?(method_name)
        end

        def header_from(node)
          method, _args, _body = *node
          _receiver, method_name, _object = *method
          %(#{method_name} "works", :aggregate_failures do)
        end

        def body_from(node, base_indent = '')
          _method, _args, body = *node
          "#{base_indent}#{indent}#{body.source}"
        end

        def indent
          @indent ||= " " * (config.for_cop('IndentationWidth')['Width'] || 2)
        end
      end
    end
  end
end
