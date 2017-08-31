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

  context "CustomEvents" do
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
end
