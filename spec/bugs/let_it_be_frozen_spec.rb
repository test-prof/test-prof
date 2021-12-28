# frozen_string_literal: true

# https://github.com/test-prof/test-prof/issues/224
describe "let_it_be vs frozen objects vs RSpec shared", type: :integration do
  specify do
    output = run_rspec(
      "let_it_be_frozen",
      chdir: File.join(__dir__, "fixtures")
    )

    expect(output).to include("6 examples, 0 failures")
  end
end
