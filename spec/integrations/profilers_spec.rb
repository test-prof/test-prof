# frozen_string_literal: true

PROFILERS_AVAILABLE =
  begin
    require "stackprof"
    require "ruby-prof"
    require "vernier"
  rescue LoadError
  end

describe "general profilers", skip: !PROFILERS_AVAILABLE do
  context "RSpec integration" do
    context "ruby prof" do
      specify "per example" do
        output = run_rspec("ruby_prof")

        expect(output).to match(/RubyProf report generated.+ruby_prof_fixture-rb-1-1/)
        expect(output).to include("0 failures")
      end

      specify "global" do
        output = run_rspec("ruby_prof", env: {"TEST_RUBY_PROF" => "1"})

        expect(output).to include("RubyProf enabled globally")
        expect(output).to include("RubyProf report generated")
        expect(output).to include("0 failures")
      end

      specify "examples only" do
        output = run_rspec("ruby_prof", env: {"TEST_RUBY_PROF" => "1", "TEST_RUBY_PROF_BOOT" => "0"})

        expect(output).to include("RubyProf enabled for examples")
        expect(output).to include("RubyProf report generated")
        expect(output).to include("0 failures")
      end
    end

    context "stackprof" do
      specify "per example", skip: "StackProf crashes with segfault occasianally" do
        output = run_rspec("stackprof")

        expect(output).to match(/StackProf report generated.+stackprof_fixture-rb-1-1/)
        expect(output).to include("0 failures")
      end

      specify "global" do
        output = run_rspec("stackprof", env: {"TEST_STACK_PROF" => "1"})

        expect(output).to include("StackProf (raw) enabled globally")
        expect(output).to include("StackProf report generated")
        expect(output).to include("StackProf JSON report generated")
        expect(output).to include("0 failures")
      end
    end

    context "vernier" do
      specify "per example" do
        output = run_rspec("vernier")

        expect(output).to match(/Vernier report generated.+vernier_fixture-rb-1-1/)
        expect(output).to include("0 failures")
      end

      specify "global" do
        output = run_rspec("vernier", env: {"TEST_VERNIER" => "1"})

        expect(output).to include("Vernier enabled globally")
        expect(output).to include("Vernier report generated")
        expect(output).to include("0 failures")
      end

      specify "with hooks vernier contains rails events" do
        output = run_rspec("vernier", env: {"TEST_VERNIER_HOOKS" => "rails"})
        sample_rails_event = "load_config_initializer.railties"
        vernier_report = File.read("tmp/test_prof/vernier-report-wall--vernier_fixture-rb-1-1-.json")

        expect(output).to include("0 failures")
        expect(vernier_report).to match(/#{sample_rails_event}/)
      end
    end
  end

  context "Minitest integration" do
    context "rubyprof" do
      specify "global" do
        output = run_minitest("profilers", env: {"TEST_RUBY_PROF" => "1"})

        expect(output).to include("RubyProf enabled globally")
        expect(output).to include("RubyProf report generated")
        expect(output).to include("0 failures, 0 errors")
      end
    end

    context "stackprof" do
      specify "global" do
        output = run_minitest("profilers", env: {"TEST_STACK_PROF" => "1"})

        expect(output).to include("StackProf (raw) enabled globally")
        expect(output).to include("StackProf report generated")
        expect(output).to include("0 failures, 0 errors")
      end
    end
  end
end
