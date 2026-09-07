# frozen_string_literal: true

describe "EventProf" do
  specify "Minitest integration with default rank by time", :aggregate_failures do
    output = run_minitest("event_prof", env: {"EVENT_PROF" => "test.event"})

    expect(output).to include("EventProf results for test.event")
    expect(output).to match(/Total time: 00:00\.514 of 00:01\.\d{3} \(\d{2}\.\d+%\)/)
    expect(output).to include("Total events: 10")

    expect(output).to include("Top 5 slowest suites (by time):")
    expect(output).to include("Top 5 slowest tests (by time):")

    expect(output).to match(/Something \(\.\/event_prof_fixture\.rb\) – 00:00\.214 \(7 \/ 3\) of 00:00\.7\d{2} \(\d{2}\.\d+%\)/)
    expect(output).to match(/Another something \(\.\/event_prof_fixture\.rb\) – 00:00\.300 \(3 \/ 2\) of 00:00\.3\d{2} \(\d{2}.\d+%\)/)

    expect(output).to match(/do very long ...nvokes 3 times \(\.\/event_prof_fixture\.rb:\d+\) – 00:00\.300 \(3\) of 00:00\.3\d{2} \(\d{2}\.\d+%\)/)
    expect(output).to match(/invokes many times \(\.\/event_prof_fixture\.rb:\d+\) – 00:00\.136 \(4\) of 00:00\.4\d{2} \(\d{2}.\d+%\)/)
    expect(output).to match(/invokes once \(\.\/event_prof_fixture\.rb:\d+\) – 00:00\.040 \(1\) of 00:00\.1\d{2} \(\d{2}\.\d+%\)/)
    expect(output).to match(/invokes twice \(\.\/event_prof_fixture\.rb:\d+\) – 00:00\.038 \(2\) of 00:00\.2\d{2} \(\d{1,2}.\d+%\)/)
  end
  specify "Minitest integration with rank by count", :aggregate_failures do
    output = run_minitest(
      "event_prof",
      env: {"EVENT_PROF" => "test.event", "EVENT_PROF_RANK" => "count"}
    )

    expect(output).to include("EventProf results for test.event")
    expect(output).to match(/Total time: 00:00\.514 of 00:01\.\d{3} \(\d{2}\.\d+%\)/)
    expect(output).to include("Total events: 10")

    expect(output).to include("Top 5 slowest suites (by count):")
    expect(output).to include("Top 5 slowest tests (by count):")

    expect(output).to match(/Something \(\.\/event_prof_fixture\.rb\) – 00:00\.214 \(7 \/ 3\) of 00:00\.7\d{2} \(\d{2}\.\d+%\)/)
    expect(output).to match(/Another something \(\.\/event_prof_fixture\.rb\) – 00:00\.300 \(3 \/ 2\) of 00:00\.3\d{2} \(\d{2}.\d+%\)/)

    expect(output).to match(/do very long ...nvokes 3 times \(\.\/event_prof_fixture\.rb:\d+\) – 00:00\.300 \(3\) of 00:00\.3\d{2} \(\d{2}\.\d+%\)/)
    expect(output).to match(/invokes many times \(\.\/event_prof_fixture\.rb:\d+\) – 00:00\.136 \(4\) of 00:00\.4\d{2} \(\d{2}.\d+%\)/)
    expect(output).to match(/invokes once \(\.\/event_prof_fixture\.rb:\d+\) – 00:00\.040 \(1\) of 00:00\.1\d{2} \(\d{2}\.\d+%\)/)
    expect(output).to match(/invokes twice \(\.\/event_prof_fixture\.rb:\d+\) – 00:00\.038 \(2\) of 00:00\.2\d{2} \(\d{1,2}.\d+%\)/)
  end

  context "with JSON format" do
    let(:artifact) { "tmp/test_prof/event-prof.json" }

    after { FileUtils.rm_f(artifact) }

    specify "it writes results to a JSON artifact", :aggregate_failures do
      output = run_minitest(
        "event_prof_json",
        env: {"EVENT_PROF" => "test.event", "EVENT_PROF_FORMAT" => "json"}
      )

      expect(output).to include("EventProf results to JSON: ")
      expect(output).not_to include("Top 5 slowest suites")

      expect(File.exist?(artifact)).to eq true

      data = JSON.parse(File.read(artifact))

      expect(data.size).to eq 1

      result = data.first

      expect(result["event"]).to eq "test.event"
      expect(result["total_count"]).to eq 3

      expect(result["groups"].size).to eq 1

      group = result["groups"].first
      expect(group["description"]).to eq "Something"
      expect(group["location"]).to eq "./event_prof_json_fixture.rb"
      expect(group["count"]).to eq 3
      expect(group["examples"]).to eq 2

      expect(result["examples"].size).to eq 2

      example = result["examples"].first
      expect(example["description"]).to eq "invokes once"
      expect(example["count"]).to eq 1
    end

    specify "it works with CLI options" do
      output = run_minitest(
        "event_prof_json",
        env: {"TESTOPTS" => "--event-prof=test.event --event-prof-format=json"}
      )

      expect(output).to include("EventProf results to JSON: ")
      expect(File.exist?(artifact)).to eq true
    end
  end

  context "CustomEvents" do
    it "works with factory.create" do
      output = run_minitest(
        "event_prof_factory_create",
        env: {"EVENT_PROF" => "factory.create"}
      )

      expect(output).to include("EventProf results for factory.create")
      expect(output).to match(/Total time: \d{2}:\d{2}\.\d{3}/)
      expect(output).to include("Total events: 3")

      expect(output).to match(%r{Post \(./event_prof_factory_create_fixture.rb\) – \d{2}:\d{2}.\d{3} \(2 / 1\)})
      expect(output).to match(%r{User \(./event_prof_factory_create_fixture.rb\) – \d{2}:\d{2}.\d{3} \(1 / 1\)})
    end

    it "works with sidekiq.inline" do
      output = run_minitest(
        "event_prof_sidekiq",
        env: {"EVENT_PROF" => "sidekiq.inline"}
      )

      expect(output).to include("EventProf results for sidekiq.inline")
      expect(output).to match(/Total time: \d{2}:\d{2}\.\d{3}/)
      expect(output).to include("Total events: 3")

      expect(output).to match(%r{SingleJob \(./event_prof_sidekiq_fixture.rb\) – \d{2}:\d{2}.\d{3} \(2 / 2\)})
      expect(output).to match(%r{BatchJob \(./event_prof_sidekiq_fixture.rb\) – \d{2}:\d{2}.\d{3} \(1 / 2\)})
    end

    it "works with sidekiq.jobs" do
      output = run_minitest(
        "event_prof_sidekiq",
        env: {"EVENT_PROF" => "sidekiq.jobs"}
      )

      expect(output).to include("EventProf results for sidekiq.jobs")
      expect(output).to match(/Total time: \d{2}:\d{2}\.\d{3}/)
      expect(output).to include("Total events: 6")

      expect(output).to include("Top 5 slowest suites (by count):")

      expect(output).to match(%r{SingleJob \(./event_prof_sidekiq_fixture.rb\) – \d{2}:\d{2}.\d{3} \(2 / 2\)})
      expect(output).to match(%r{BatchJob \(./event_prof_sidekiq_fixture.rb\) – \d{2}:\d{2}.\d{3} \(4 / 2\)})
    end
  end
end
