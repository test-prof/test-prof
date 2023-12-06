# frozen_string_literal: true

describe "FactoryProf" do
  context "RSpec integration" do
    specify "simple printer", :aggregate_failures do
      output = run_rspec("factory_prof", env: {"FPROF" => "1"})

      expect(output).to include("FactoryProf enabled (simple mode)")

      expect(output).to include("Factories usage")
      expect(output).to match(/Total: 26\n\s+Total top-level: 14\n\s+Total time: \d{2}+:\d{2}\.\d{3} \(out of \d{2}+:\d{2}\.\d{3}\)\n\s+Total uniq factories: 2/)
      expect(output).to match(/total\s+top-level\s+total time\s+time per call\s+top-level time\s+name/)
      expect(output).to match(/\s+16\s+8\s+(\d+\.\d{4}s\s+){3}user\n\s+10\s+6\s+\s+(\d+\.\d{4}s\s+){3}post/)
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
