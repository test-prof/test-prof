# frozen_string_literal: true

require "spec_helper"

describe "EventProf" do
  specify "RSpec integration", :aggregate_failures do
    output = run_rspec('event_prof', env: { 'EVENT_PROF' => 'test.event' })

    expect(output).to include("EventProf results for test.event")
    expect(output).to match(/Total time: 25:56\.\d{3}/)
    expect(output).to include("Total events: 8")

    expect(output).to include("Top 5 slowest suites (by time):")
    expect(output).to include("Top 5 slowest tests (by time):")

    expect(output).to include(
      "Another something (./event_prof_fixture.rb:42) – 16:40.000 (1 / 2)\n"\
      "Something (./event_prof_fixture.rb:21) – 09:16.100 (7 / 3)"
    )

    expect(output).to include(
      "do very long (./event_prof_fixture.rb:47) – 16:40.000 (1)\n"\
      "invokes twice (./event_prof_fixture.rb:27) – 06:20.000 (2)\n"\
      "invokes many times (./event_prof_fixture.rb:33) – 02:16.000 (4)\n"\
      "invokes once (./event_prof_fixture.rb:22) – 00:40.100 (1)"
    )
  end

  specify "RSpec integration with rank by count", :aggregate_failures do
    output = run_rspec(
      'event_prof',
      env: { 'EVENT_PROF' => 'test.event', 'EVENT_PROF_RANK' => 'count' }
    )

    expect(output).to include("EventProf results for test.event")
    expect(output).to match(/Total time: 25:56\.\d{3}/)
    expect(output).to include("Total events: 8")

    expect(output).to include("Top 5 slowest suites (by count):")
    expect(output).to include("Top 5 slowest tests (by count):")

    expect(output).to include(
      "Something (./event_prof_fixture.rb:21) – 09:16.100 (7 / 3)\n"\
      "Another something (./event_prof_fixture.rb:42) – 16:40.000 (1 / 2)"
    )

    expect(output).to include(
      "invokes many times (./event_prof_fixture.rb:33) – 02:16.000 (4)\n"\
      "invokes twice (./event_prof_fixture.rb:27) – 06:20.000 (2)\n"\
      "invokes once (./event_prof_fixture.rb:22) – 00:40.100 (1)\n"\
      "do very long (./event_prof_fixture.rb:47) – 16:40.000 (1)"
    )
  end
end
