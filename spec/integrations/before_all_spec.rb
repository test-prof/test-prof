# frozen_string_literal: true

describe "BeforeAll" do
  context "RSpec" do
    it "works" do
      output = run_rspec("before_all")

      expect(output).to include("0 failures")
    end

    specify "global hooks" do
      output = run_rspec("before_all_hooks")

      expect(output).to include("0 failures")
    end

    specify "custom adapter" do
      output = run_rspec("before_all_custom_adapter")

      expect(output).to include("0 failures")
    end

    it "works with isolator" do
      output = run_rspec("before_all_isolator", success: false)

      expect(output).to include("3 examples, 1 failure")
      expect(output).not_to include("SampleJob")
      expect(output).to include("FailingJob")
    end

    it "works with Rails fixtures" do
      output = run_rspec("before_all_rails_fixtures", success: true)

      expect(output).to include("examples, 0 failures")
    end

    specify "database connection" do
      output = run_rspec("before_all_connection")

      expect(output).to include("0 failures")
    end

    specify "dry-run" do
      output = run_rspec("before_all", options: "--dry-run", env: {"DRY_RUN" => "true", "DB" => "postgres", "DATABASE_URL" => "postgres://bla-bla-host/test_prof_test"})

      expect(output).to include("0 failures")
    end
  end

  context "Minitest" do
    specify do
      output = run_minitest("before_all")

      expect(output).to include("0 failures, 0 errors, 0 skips")
    end

    specify "after_all" do
      output = run_minitest("before_all")

      expect(output).to include("WE ALL HUMANS AFTER ALL: 1")
    end

    specify "inheritance" do
      output = run_minitest("before_all_inherit")

      expect(output).to include("0 failures, 0 errors, 0 skips")
    end

    specify "database connection" do
      output = run_minitest("before_all_connection")

      expect(output).to include("0 failures, 0 errors, 0 skip")
    end
  end
end
