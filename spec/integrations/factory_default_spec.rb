# frozen_string_literal: true

describe "FactoryDefault", :aggregate_failures do
  context "RSpec integration" do
    specify "basic" do
      output = run_rspec("factory_default")

      expect(output).to include("0 failures")
    end

    specify "fabrication" do
      output = run_rspec("factory_default_fabrication")

      expect(output).to include("0 failures")
    end

    specify "let_it_be integration" do
      output = run_rspec("factory_default_let_it_be")

      expect(output).to include("0 failures")
    end

    specify "stats" do
      output = run_rspec("factory_default", env: {"FACTORY_DEFAULT_STATS" => "1"})

      expect(output).to include("0 failures")

      expect(output).to include("FactoryDefault summary: hit=11 miss=3")
      expect(output).to match(/factory\s+hit\s+miss\n\n/)
      expect(output).to match(/user\s+11\s+3/)
    end

    specify "fabrication stats" do
      output = run_rspec("factory_default_fabrication", env: {"FACTORY_DEFAULT_STATS" => "1"})

      expect(output).to include("0 failures")

      expect(output).to include("FactoryDefault summary: hit=7 miss=1")
      expect(output).to match(/factory\s+hit\s+miss\n\n/)
      expect(output).to match(/user\s+7\s+1/)
    end

    specify "analyze" do
      output = run_rspec(
        "factory_default_analyze",
        env: {
          "FACTORY_DEFAULT_PROF" => "1"
        }
      )

      expect(output).to include("0 failures")

      expect(output).to include("Factory associations usage:")
      expect(output).to match(/factory\s+count\s+total time\n\n/)
      expect(output).to match(/user\s+7\s+\d{2}:\d{2}\.\d{3}/)
      expect(output).to match(/user\[traited\]\s+1\s+\d{2}:\d{2}\.\d{3}/)
      expect(output).to match(/user\{tag:"some tag"\}\s+1\s+\d{2}:\d{2}\.\d{3}/)
      expect(output).to include("Total associations created: 9")
      expect(output).to include("Total uniq associations created: 3")
      expect(output).to match(/Total time spent: \d{2}:\d{2}\.\d{3}/)
      expect(output).to include("0 failures")
    end
  end
end
