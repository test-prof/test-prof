# frozen_string_literal: true

# https://github.com/test-prof/test-prof/issues/265
describe "let_it_be + mysql + savepoints", type: :integration do
  specify "works" do
    output = run_rspec(
      "let_it_be_savepoint",
      chdir: File.join(__dir__, "fixtures")
    )

    expect(output).to include("0 failures")
  end
end
