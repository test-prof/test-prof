# frozen_string_literal: true

# https://github.com/test-prof/test-prof/issues/358
describe "before_all + pool created during transaction", type: :integration do
  specify "works" do
    output = run_rspec(
      "before_all_unpinned_pool",
      chdir: File.join(__dir__, "fixtures")
    )

    expect(output).to include("2 examples, 0 failures")
    expect(output).not_to include("occurred outside of examples")
  end
end
