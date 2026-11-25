# frozen_string_literal: true

describe "EventProf with cross-thread factory.create", type: :integration do
  specify do
    output = run_rspec(
      "event_prof_cross_thread",
      chdir: File.join(__dir__, "fixtures"),
      env: {"EVENT_PROF" => "factory.create"}
    )

    expect(output).to include("2 examples, 0 failures")
    expect(output).to include("EventProf results for factory.create")
    expect(output).to include("Total events: 2")
  end
end
