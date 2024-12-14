# frozen_string_literal: true

# https://github.com/test-prof/test-prof/issues/310
describe "before_all + any_fixture + multidb", type: :integration do
  specify "works" do
    output = run_rspec(
      "before_all_any_fixture_multidb",
      chdir: File.join(__dir__, "fixtures")
    )

    expect(output).to include("0 failures")
  end
end
