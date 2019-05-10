# frozen_string_literal: true

require "spec_helper"

describe "FactoryProf" do
  context "RSpec integration" do
    specify "simple printer", :aggregate_failures do
      output = run_rspec("factory_prof", env: {"FPROF" => "1"})

      expect(output).to include("FactoryProf enabled (simple mode)")

      expect(output).to include("Factories usage")
      expect(output).to match(/Total: 26\n\s+Total top-level: 14\n\s+Total time: \d+\.\d{4}s\n\s+Total uniq factories: 2/)
      expect(output).to match(/total\s+top\-level\s+total time\s+top\-level time\s+name\n\n\s+16\s+8\s+(\d+\.\d{4}s\s+){2}user\n\s+10\s+6\s+\s+(\d+\.\d{4}s\s+){2}post/)
    end

    specify "flamegraph printer" do
      output = run_rspec("factory_prof", env: {"FPROF" => "flamegraph"})

      expect(output).to include("FactoryProf enabled (flamegraph mode)")

      expect(output).to include("FactoryFlame report generated: ")

      expect(File.exist?("tmp/factory-flame.html")).to eq true
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
