# frozen_string_literal: true

require 'spec_helper'

describe 'EventProf Minitest integration' do
  context 'Minitest integration' do
    specify 'with default rank by time', :aggregate_failures do
      output = run_minitest('event_prof', env: { 'EVENT_PROF' => 'test.event' })

      expect(output).to include("EventProf results for test.event")
      expect(output).to match(/Total time: 59:16\.\d{3}/)
      expect(output).to include("Total events: 10")

      expect(output).to include("Top 5 slowest suites (by time):")
      expect(output).to include("Top 5 slowest tests (by time):")

      expect(output).to include(
        "Another something (./event_prof_fixture.rb) – 50:00.000 (3 / 2)\n"\
        "Something (./event_prof_fixture.rb) – 09:16.100 (7 / 3)"
      )

      expect(output).to include(
        "do very long ...nvokes 3 times (./event_prof_fixture.rb:48) – 50:00.000 (3)\n"\
        "invokes twice (./event_prof_fixture.rb:28) – 06:20.000 (2)\n"\
        "invokes many times (./event_prof_fixture.rb:34) – 02:16.000 (4)\n"\
        "invokes once (./event_prof_fixture.rb:23) – 00:40.100 (1)"
      )
    end
    specify 'with rank by count', :aggregate_failures  do
      output = run_minitest(
        'event_prof',
        env: { 'EVENT_PROF' => 'test.event', 'EVENT_PROF_RANK' => 'count' }
      )

      expect(output).to include("EventProf results for test.event")
      expect(output).to match(/Total time: 59:16\.\d{3}/)
      expect(output).to include("Total events: 10")

      expect(output).to include("Top 5 slowest suites (by count):")
      expect(output).to include("Top 5 slowest tests (by count):")

      expect(output).to include(
        "Something (./event_prof_fixture.rb) – 09:16.100 (7 / 3)\n"\
        "Another something (./event_prof_fixture.rb) – 50:00.000 (3 / 2)"
      )

      expect(output).to include(
        "invokes many times (./event_prof_fixture.rb:34) – 02:16.000 (4)\n"\
        "do very long ...nvokes 3 times (./event_prof_fixture.rb:48) – 50:00.000 (3)\n"\
        "invokes twice (./event_prof_fixture.rb:28) – 06:20.000 (2)\n"\
        "invokes once (./event_prof_fixture.rb:23) – 00:40.100 (1)\n"\
      )
    end
  end
end
