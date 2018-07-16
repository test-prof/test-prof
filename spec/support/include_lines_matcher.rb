# frozen_string_literal: true

# Verify that the actual string contains all lines that included the specified
# lines in the provided order.
#
#   Example:
#
#   text = <<~TXT
#     Jingle bells,
#     Jingle bells,
#     Jingle all the way
#   TXT
#
#   # passes
#   expect(text).to include_lines("Jingle bells", "Jingle bells")
#
#   # passes
#   expect(text).to include_lines("Jingle bells", "Jingle all the")
#
#   # do not pass
#   expect(text).to include_lines("Jingle all the way", "Jingle bells")
::RSpec::Matchers.define :include_lines do |*lines|
  match do |actual|
    actual.each_line do |line|
      lines.shift if line.include?(lines.first)
      break if lines.empty?
    end

    lines.empty?
  end

  match_when_negated do |_actual|
    raise "This matcher doesn't support negation"
  end

  failure_message do |actual|
    <<~MSG
      Couldn't find lines:

      #{lines.join("\n")}

      in the output:

      #{actual}"
    MSG
  end
end
