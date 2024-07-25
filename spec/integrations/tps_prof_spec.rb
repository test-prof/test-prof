# frozen_string_literal: true

describe "TPSProf" do
  context "RSpec" do
    specify "with default options", :aggregate_failures do
      output = run_rspec("tps_prof", env: {"TPS_PROF" => "1", "TPS_PROF_MIN" => "2"})

      expect(output).to include("TPSProf enabled (top-10)")
      expect(output).to match(/Total TPS \(tests per second\): 2\.\d+/)

      expect(output).to match(/Another something \(\.\/tps_prof_fixture\.rb:\d+\) – 0\.\d+ TPS \(00:\d{2}\.\d{3} \/ 2\), group time: 00:01\.\d{3}/)
      expect(output).to match(/Something \(\.\/tps_prof_fixture\.rb:\d+\) – 3\.\d+ TPS \(00:\d{2}\.\d{3} \/ 2\), group time: 00:\d{2}\.\d{3}/)
    end
  end
end
