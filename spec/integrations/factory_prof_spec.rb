# frozen_string_literal: true

describe "FactoryProf" do
  context "RSpec integration" do
    specify "simple printer", :aggregate_failures do
      output = run_rspec("factory_prof", env: {"FPROF" => "1"})

      expect(output).to include("FactoryProf enabled (simple mode)")

      expect(output).to include("Factories usage")
      expect(output).to match(/Total: 26\n\s+Total top-level: 14\n\s+Total time: \d{2}+:\d{2}\.\d{3} \(out of \d{2}+:\d{2}\.\d{3}\)\n\s+Total uniq factories: 2/)
      expect(output).to match(/name\s+total\s+top-level\s+total time\s+time per call\s+top-level time/)
      expect(output).to match(
        /
          user\s+16\s+8\s+(\d+\.\d{4}s\s+){2}\d+\.\d{4}s\n
          \s+post\s+10\s+6\s+(\d+\.\d{4}s\s+){2}\d+\.\d{4}s\n
        /x
      )
    end

    specify "simple printer with variations", :aggregate_failures do
      output = run_rspec("factory_prof_with_variations", env: {"FPROF" => "1", "FPROF_VARS" => "1", "FPROF_VARIATIONS_LIMIT" => "2"})

      expect(output).to include("FactoryProf enabled (simple mode)")

      expect(output).to include("Factories usage")
      expect(output).to match(/Total: 25\n\s+Total top-level: 9\n\s+Total time: \d{2}+:\d{2}\.\d{3} \(out of \d{2}+:\d{2}\.\d{3}\)\n\s+Total uniq factories: 2/)
      expect(output).to match(/name\s+total\s+top-level\s+total time\s+time per call\s+top-level time/)
      expect(output).to match(
        /
          user\s+15\s+7\s+(\d+\.\d{4}s\s+){2}\d+\.\d{4}s\n
          \s+.traited.with_posts\s+2\s+2\s+(\d+\.\d{4}s\s+){2}\d+\.\d{4}s\n
          \s+\[name\]\s+2\s+2\s+(\d+\.\d{4}s\s+){2}\d+\.\d{4}s\n
          \s+\[...\]\s+2\s+2\s+(\d+\.\d{4}s\s+){2}\d+\.\d{4}s\n
          \s+post\s+10\s+2\s+(\d+\.\d{4}s\s+){2}\d+\.\d{4}s\n
          \s+\[text,\suser\]\s+2\s+2\s+(\d+\.\d{4}s\s+){2}\d+\.\d{4}s
        /x
      )
    end

    specify "simple printer with threshold param", :aggregate_failures do
      output = run_rspec("factory_prof", env: {"FPROF" => "1", "FPROF_THRESHOLD" => "11"})

      expect(output).to include("FactoryProf enabled (simple mode)")

      expect(output).to include("Factories usage")
      expect(output).to match(/Total: 26\n\s+Total top-level: 14\n\s+Total time: \d{2}+:\d{2}\.\d{3} \(out of \d{2}+:\d{2}\.\d{3}\)\n\s+Total uniq factories: 2/)
      expect(output).to match(/name\s+total\s+top-level\s+total time\s+time per call\s+top-level time/)
      expect(output).to match(/user\s+16\s+8\s+(\d+\.\d{4}s\s+){2}\d+\.\d{4}s\n/)
      expect(output).not_to match(/\s+post\s+10\s+2\s+(\d+\.\d{4}s\s+){2}\d+\.\d{4}s\n/)
    end

    specify "flamegraph printer" do
      output = run_rspec("factory_prof", env: {"FPROF" => "flamegraph"})

      expect(output).to include("FactoryProf enabled (flamegraph mode)")

      expect(output).to include("FactoryFlame report generated: ")

      expect(File.exist?("tmp/test_prof/factory-flame.html")).to eq true
    end

    specify "nate printer", :aggregate_failures do
      output = run_rspec("factory_prof", env: {"FPROF" => "nate_heckler"})

      expect(output).to match(/Time spent in factories: \d{2}+:\d{2}\.\d{3} \([\d.]+% of total time\)/)
    end

    specify "with nate printer always enabled", :aggregate_failures do
      output = run_rspec("factory_prof_with_nate")

      expect(output).to match(/Time spent in factories: \d{2}+:\d{2}\.\d{3} \([\d.]+% of total time\)/)
    end

    specify "with nate printer always enabled and flamegraph profiler", :aggregate_failures do
      output = run_rspec("factory_prof_with_nate", env: {"FPROF" => "flamegraph"})

      expect(output).to match(/Time spent in factories: \d{2}+:\d{2}\.\d{3} \([\d.]+% of total time\)/)
      expect(output).to include("FactoryProf enabled (flamegraph mode)")
      expect(output).to include("FactoryFlame report generated: ")
    end

    specify "with nate printer always enabled and json profiler", :aggregate_failures do
      output = run_rspec("factory_prof_with_nate", env: {"FPROF" => "json"})

      expect(output).to match(/Time spent in factories: \d{2}+:\d{2}\.\d{3} \([\d.]+% of total time\)/)
      expect(output).to include("Profile results to JSON: ")
    end

    context "when no fabrication installed" do
      specify "simple printer", :aggregate_failures do
        output = run_rspec("factory_prof_no_fabrication", env: {"FPROF" => "1"})
        expect(output).to include("FactoryProf enabled (simple mode)")
        expect(output).to include("No factories detected")
        expect(output).not_to include("[TEST PROF ERROR]")
      end
    end

    context "when no factory_bot installed" do
      specify "simple printer", :aggregate_failures do
        output = run_rspec("factory_prof_no_factory_bot", env: {"FPROF" => "1"})
        expect(output).to include("FactoryProf enabled (simple mode)")
        expect(output).to include("No factories detected")
        expect(output).not_to include("[TEST PROF ERROR]")
      end
    end
  end
end
