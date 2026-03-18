# frozen_string_literal: true

describe "TPSProf" do
  context "RSpec" do
    specify "with default options", :aggregate_failures do
      output = run_rspec("tps_prof", env: {"TPS_PROF" => "1", "TPS_PROF_MIN_EXAMPLES" => "2", "TPS_PROF_MIN_TIME" => "0"})

      expect(output).to include("TPSProf enabled (top-10)")
      expect(output).to match(/Total TPS \(tests per second\): 2\.\d+/)

      expect(output).to match(/Another something \(\.\/tps_prof_fixture\.rb:\d+\) – 0\.\d+ TPS \(00:\d{2}\.\d{3} \/ 2, shared setup time: 00:01\.\d{3}\)/)
      expect(output).to match(/Something \(\.\/tps_prof_fixture\.rb:\d+\) – 3\.\d+ TPS \(00:\d{2}\.\d{3} \/ 2, shared setup time: 00:\d{2}\.\d{3}\)/)
    end

    specify "with strict mode" do
      output = run_rspec("tps_prof", success: false, env: {"TPS_PROF" => "strict", "TPS_PROF_MIN_EXAMPLES" => "2", "TPS_PROF_MIN_TIME" => "0", "TPS_PROF_MAX_EXAMPLES" => "4", "TPS_PROF_MIN_TPS" => "1"})

      expect(output).to include("TPSProf strict enabled (max examples: 4, min tps: 1)")
      expect(output).to match(/Total TPS \(tests per second\): 2\.\d+/)

      expect(output).to include("6 examples, 0 failures, 1 error")
    end

    specify "with custom strict handler" do
      output = run_rspec("tps_prof", success: false, env: {"TPS_PROF" => "strict", "TPS_PROF_MIN_EXAMPLES" => "2", "TPS_PROF_MIN_TIME" => "0", "CUSTOM_STRICT_HANDLER" => "1"})

      expect(output).to include("TPSProf strict enabled (custom handler)")
      expect(output).to match(/Total TPS \(tests per second\): 2\.\d+/)

      expect(output).to include("I don't like this example group")

      expect(output).to include("6 examples, 0 failures, 2 errors")
    end
  end
end
