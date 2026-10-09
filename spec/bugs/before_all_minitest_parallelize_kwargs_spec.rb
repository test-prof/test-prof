# frozen_string_literal: true

describe "before_all + parallelize keyword arguments", type: :integration do
  specify "forwards unknown keyword arguments to the original parallelize" do
    output = run_minitest("before_all_minitest_parallelize_kwargs", chdir: File.join(__dir__, "fixtures"))

    expect(output).to include("1 runs, 2 assertions, 0 failures, 0 errors")
  end
end
