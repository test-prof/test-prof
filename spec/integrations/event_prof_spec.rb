# frozen_string_literal: true

require "spec_helper"

describe "EventProf RSpec" do
  specify "with default options", :aggregate_failures do
    output = run_rspec('event_prof', env: { 'EVENT_PROF' => 'test.event' })

    expect(output).to include("EventProf results for test.event")
    expect(output).to match(/Total time: 00:00\.359 of 00:01\.\d{3} \(\d{2}\.\d+%\)/)
    expect(output).to include("Total events: 8")

    expect(output).to include("Top 5 slowest suites (by time):")
    expect(output).to include("Top 5 slowest tests (by time):")

    expect(output).to match(/Something \(\.\/event_prof_fixture\.rb:22\) – 00:00\.214 \(7 \/ 3\) of 00:0\d\.\d{3} \(\d{2}\.\d+%\)/)
    expect(output).to match(/Another something \(\.\/event_prof_fixture\.rb:45\) – 00:00\.145 \(1 \/ 2\) of 00:00\.2\d{2} \(\d{2}.\d+%\)/)

    expect(output).to match(/do very long \(\.\/event_prof_fixture\.rb:50\) – 00:00\.145 \(1\) of 00:00\.2\d{2} \(\d{2}\.\d+%\)/)
    expect(output).to match(/invokes many times \(\.\/event_prof_fixture\.rb:35\) – 00:00\.136 \(4\) of 00:00\.5\d{2} \(\d{2}.\d+%\)/)
    expect(output).to match(/invokes once \(\.\/event_prof_fixture\.rb:23\) – 00:00\.040 \(1\) of 00:00\.\d{3} \(\d{2}\.\d+%\)/)
    expect(output).to match(/invokes twice \(\.\/event_prof_fixture\.rb:28\) – 00:00\.038 \(2\) of 00:00\.\d{3} \(\d{1,2}.\d+%\)/)
  end

  specify "with rank by count", :aggregate_failures do
    output = run_rspec(
      'event_prof',
      env: { 'EVENT_PROF' => 'test.event', 'EVENT_PROF_RANK' => 'count' }
    )

    expect(output).to include("EventProf results for test.event")
    expect(output).to match(/Total time: 00:00\.359 of 00:01\.\d{3} \(\d{2}\.\d+%\)/)
    expect(output).to include("Total events: 8")

    expect(output).to include("Top 5 slowest suites (by count):")
    expect(output).to include("Top 5 slowest tests (by count):")

    expect(output).to match(/Something \(\.\/event_prof_fixture\.rb:22\) – 00:00\.214 \(7 \/ 3\) of 00:0\d\.\d{3} \(\d{2}\.\d+%\)/)
    expect(output).to match(/Another something \(\.\/event_prof_fixture\.rb:45\) – 00:00\.145 \(1 \/ 2\) of 00:00\.2\d{2} \(\d{2}.\d+%\)/)

    expect(output).to match(/do very long \(\.\/event_prof_fixture\.rb:50\) – 00:00\.145 \(1\) of 00:00\.2\d{2} \(\d{2}\.\d+%\)/)
    expect(output).to match(/invokes many times \(\.\/event_prof_fixture\.rb:35\) – 00:00\.136 \(4\) of 00:00\.5\d{2} \(\d{2}.\d+%\)/)
    expect(output).to match(/invokes once \(\.\/event_prof_fixture\.rb:23\) – 00:00\.040 \(1\) of 00:00\.\d{3} \(\d{2}\.\d+%\)/)
    expect(output).to match(/invokes twice \(\.\/event_prof_fixture\.rb:28\) – 00:00\.038 \(2\) of 00:00\.\d{3} \(\d{1,2}.\d+%\)/)
  end

  specify "with multiple events", :aggregate_failures do
    output = run_rspec('event_prof', env: { 'EVENT_PROF' => 'test.event,test.another_event' })

    expect(output).to include("EventProf results for test.event")
    expect(output).to match(/Total time: 00:00\.359 of 00:01\.\d{3} \(\d{2}\.\d+%\)/)
    expect(output).to include("Total events: 8")

    expect(output).to include("EventProf results for test.another_event")
    expect(output).to match(/Total time: 00:00\.154 of 00:01\.\d{3} \(\d{2}\.\d+%\)/)
    expect(output).to include("Total events: 3")
  end

  context "with RStamp" do
    before do
      FileUtils.cp(
        File.expand_path("../../integrations/fixtures/rspec/event_prof_stamp_fixture_tmpl.rb", __FILE__),
        File.expand_path("../../integrations/fixtures/rspec/event_prof_stamp_fixture.rb", __FILE__)
      )
    end

    after do
      FileUtils.rm(
        File.expand_path("../../integrations/fixtures/rspec/event_prof_stamp_fixture.rb", __FILE__)
      )
    end

    specify "it works with groups", :aggregate_failures do
      output = run_rspec(
        'event_prof_stamp',
        env: { 'EVENT_PROF' => 'test.event', 'EVENT_PROF_STAMP' => 'slow', 'EVENT_PROF_TOP' => '1' }
      )

      expect(output).to include("5 examples, 0 failures")

      expect(output).to include("EventProf results for test.event")
      expect(output).to include("Total events: 7")

      expect(output).to include("Top 1 slowest suites (by time):")

      expect(output).to include("RSpec Stamp results")
      expect(output).to include("Total patches: 1")
      expect(output).to include("Total files: 1")
      expect(output).to include("Failed patches: 0")
      expect(output).to include("Ignored files: 0")

      output2 = run_rspec(
        'event_prof_stamp',
        env: { 'SPEC_OPTS' => '--tag slow' }
      )

      expect(output2).to include("3 examples, 0 failures")
    end

    specify "it works with groups and examples", :aggregate_failures do
      output = run_rspec(
        'event_prof_stamp',
        env: {
          'EVENT_PROF' => 'test.event', 'EVENT_PROF_STAMP' => 'slow:test_event',
          'EVENT_PROF_TOP' => '1', 'EVENT_PROF_EXAMPLES' => '1'
        }
      )

      expect(output).to include("5 examples, 0 failures")

      expect(output).to include("EventProf results for test.event")
      expect(output).to include("Total events: 7")

      expect(output).to include("Top 1 slowest suites (by time):")
      expect(output).to include("Top 1 slowest tests (by time):")

      expect(output).to include("RSpec Stamp results")
      expect(output).to include("Total patches: 2")
      expect(output).to include("Total files: 1")
      expect(output).to include("Failed patches: 0")
      expect(output).to include("Ignored files: 0")

      output2 = run_rspec(
        'event_prof_stamp',
        env: { 'SPEC_OPTS' => '--tag slow:test_event' }
      )

      expect(output2).to include("4 examples, 0 failures")
    end
  end

  context "with custom events" do
    it "works with factory.create" do
      output = run_rspec(
        'event_prof_factory_create',
        env: { 'EVENT_PROF' => 'factory.create' }
      )

      expect(output).to include("EventProf results for factory.create")
      expect(output).to match(/Total time: \d{2}:\d{2}\.\d{3}/)
      expect(output).to include("Total events: 3")

      expect(output).to match(%r{Post \(./event_prof_factory_create_fixture.rb:7\) – \d{2}:\d{2}.\d{3} \(2 / 1\)})
      expect(output).to match(%r{User \(./event_prof_factory_create_fixture.rb:16\) – \d{2}:\d{2}.\d{3} \(1 / 1\)})
    end

    it "works with sidekiq.inline" do
      output = run_rspec(
        'event_prof_sidekiq',
        env: { 'EVENT_PROF' => 'sidekiq.inline' }
      )

      expect(output).to include("EventProf results for sidekiq.inline")
      expect(output).to match(/Total time: \d{2}:\d{2}\.\d{3}/)
      expect(output).to include("Total events: 3")

      expect(output).to match(%r{SingleJob \(./event_prof_sidekiq_fixture.rb:27\) – \d{2}:\d{2}.\d{3} \(2 / 2\)})
      expect(output).to match(%r{BatchJob \(./event_prof_sidekiq_fixture.rb:39\) – \d{2}:\d{2}.\d{3} \(1 / 2\)})
    end

    it "works with sidekiq.jobs" do
      output = run_rspec(
        'event_prof_sidekiq',
        env: { 'EVENT_PROF' => 'sidekiq.jobs' }
      )

      expect(output).to include("EventProf results for sidekiq.jobs")
      expect(output).to match(/Total time: \d{2}:\d{2}\.\d{3}/)
      expect(output).to include("Total events: 6")

      expect(output).to include("Top 5 slowest suites (by count):")

      expect(output).to match(%r{SingleJob \(./event_prof_sidekiq_fixture.rb:27\) – \d{2}:\d{2}.\d{3} \(2 / 2\)})
      expect(output).to match(%r{BatchJob \(./event_prof_sidekiq_fixture.rb:39\) – \d{2}:\d{2}.\d{3} \(4 / 2\)})
    end
  end

  context "with monitor" do
    it "profiles custom methods" do
      output = run_rspec(
        'event_prof_monitor',
        env: { 'EVENT_PROF' => 'test.event' }
      )

      expect(output).to include("EventProf results for test.event")
      expect(output).to include("Total events: 3")
      expect(output).to include_lines(
        "invokes twice (./event_prof_monitor_fixture.rb:30)",
        "invokes once (./event_prof_monitor_fixture.rb:26)"
      )
    end
  end
end
