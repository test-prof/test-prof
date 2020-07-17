# frozen_string_literal: true

describe "Tests Sampling" do
  context "RSpec integration" do
    specify "SAMPLE=2" do
      output = run_rspec("sample", env: {"SAMPLE" => "2"})

      expect(output).to include("2 examples, 0 failures")
    end

    specify "SAMPLE=1" do
      output = run_rspec("sample", env: {"SAMPLE" => "1"})

      expect(output).to include("1 example, 0 failures")
    end

    specify "SAMPLE=1 with tag filter" do
      output = run_rspec("sample", env: {"SAMPLE" => "1"}, options: "-fd --tag sometag")

      expect(output).to include("always passes with tag")
      expect(output).to include("1 example, 0 failures")
    end

    specify "SAMPLE=1 with description filter" do
      output = run_rspec("sample", env: {"SAMPLE" => "1"}, options: "-fd -e flickers")

      expect(output).to include("flickers")
      expect(output).to include("1 example, 0 failures")
    end

    specify "SAMPLE=2 with seed" do
      outputs = Array
        .new(10) { run_rspec("sample", env: {"SAMPLE" => "2"}, options: "--format=documentation --seed 42") }
        .map { |output| output.gsub(/Finished in.*/, "") }

      expect(outputs.uniq.size).to eq 1
    end

    specify "SAMPLE_GROUPS=1" do
      output = run_rspec("sample", env: {"SAMPLE_GROUPS" => "1"})

      expect(output).to include("1 example, 0 failures")
    end

    specify "SAMPLE_GROUPS=2" do
      output = run_rspec("sample", env: {"SAMPLE_GROUPS" => "2"})

      expect(output).to include("2 examples, 0 failures")
    end

    specify "SAMPLE_GROUPS=2 with seed" do
      outputs = Array
        .new(10) { run_rspec("sample", env: {"SAMPLE_GROUPS" => "2"}, options: "--format=documentation --seed 42") }
        .map { |output| output.gsub(/Finished in.*/, "").gsub(/\s/m, "") }

      expect(outputs.uniq.size).to eq(1), "Outputs must be equal:\n#{outputs.uniq.join("\n")}"
    end
  end

  context "Minitest integration" do
    specify "SAMPLE=2" do
      output = run_minitest("sample", env: {"SAMPLE" => "2"})

      expect(output).to include("2 runs, 2 assertions, 0 failures, 0 errors, 0 skips")
    end

    specify "SAMPLE=1" do
      output = run_minitest("sample", env: {"SAMPLE" => "1"})

      expect(output).to include("1 runs, 1 assertions, 0 failures, 0 errors, 0 skips")
    end

    specify "SAMPLE=2 with seed" do
      outputs = Array
        .new(10) { run_minitest("sample", env: {"SAMPLE" => "2", "TESTOPTS" => "-v --seed 42"}) }
        .map { |output| output.gsub(/Finished in.*/, "") }

      expect(outputs.uniq.size).to eq 1
    end

    specify "SAMPLE_GROUPS=1" do
      output = run_minitest("sample", env: {"SAMPLE_GROUPS" => "1"})

      expect(output).to include("2 runs, 2 assertions, 0 failures, 0 errors, 0 skips")
    end

    specify "SAMPLE_GROUPS=2" do
      output = run_minitest("sample", env: {"SAMPLE_GROUPS" => "2"})

      expect(output).to include("4 runs, 4 assertions, 0 failures, 0 errors, 0 skips")
    end

    specify "SAMPLE_GROUPS=2 with seed" do
      outputs = Array
        .new(10) { run_minitest("sample", env: {"SAMPLE_GROUPS" => "2", "TESTOPTS" => "-v --seed 42"}) }
        .map { |output| output.gsub(/Finished in.*/, "").gsub(/\s/, "") }

      expect(outputs.uniq.size).to eq(1), "Outputs must be equal:\n#{outputs.uniq.join("\n")}"
    end
  end
end
