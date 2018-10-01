# frozen_string_literal: true

require 'rubocop'
require 'test_prof/utils'

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
      #  its(:status) { is_expected.to eq(200) }
      #
      #  # good
      #  it "returns the second page", :aggregate_failures do
      #    is_expected.to be_success
      #    is_expected.to have_header('X-TOTAL-PAGES', 10)
      #    is_expected.to have_header('X-NEXT-PAGE', 2)
      #    expect(subject.status).to eq(200)
      #  end
      #
      class AggregateFailures < RuboCop::Cop::Cop
        # From https://github.com/backus/rubocop-rspec/blob/master/lib/rubocop/rspec/language.rb
        GROUP_BLOCKS = %i[
          describe context feature example_group
        ].freeze

        EXAMPLE_BLOCKS = %i[
          it its specify example scenario
        ].freeze

        class << self
          def supported?
            return @supported if instance_variable_defined?(:@supported)
            @supported = TestProf::Utils.verify_gem_version('rubocop', at_least: '0.51.0')

            unless @supported
              warn "RSpec/AggregateFailures cop requires RuboCop >= 0.51.0. Skipping"
            end

            @supported
          end
        end

        def on_block(node)
          return unless self.class.supported?

          method, _args, body = *node
          return unless body&.begin_type?

          _receiver, method_name, _object = *method
          return unless GROUP_BLOCKS.include?(method_name)

          return if check_node(body)

          add_offense(
            node,
            location: :expression,
            message: 'Use :aggregate_failures instead of several one-liners.'
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
          node&.block_type? &&
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
          method_name = :it if method_name == :its
          %(#{method_name} "works", :aggregate_failures do)
        end

        def body_from(node, base_indent = '')
          method, _args, body = *node

          if method.method_name == :its
            body_source = body_from_its(method, body)
          else
            body_source = body.source
          end

          "#{base_indent}#{indent}#{body_source}"
        end

        def body_from_its(method, body)
          subject_attribute = method.arguments.first
          expectation = body.method_name
          match = body.arguments.first.source

          if subject_attribute.array_type?
            hash_keys = subject_attribute.values.map(&:value).join(", ")
            attribute = "dig(#{hash_keys})"
          else
            attribute = subject_attribute.value
          end

          "expect(subject.#{attribute}).#{expectation} #{match}"
        end

        def indent
          @indent ||= " " * (config.for_cop('IndentationWidth')['Width'] || 2)
        end
      end
    end
  end
end
