# frozen_string_literal: true

describe "TagProf" do
  context "rspec" do
    specify "it works", :aggregate_failures do
      output = run_rspec("tag_prof", env: {"TAG_PROF" => "type"})

      expect(output).to include("TagProf report for type")
      expect(output).to match(/type\s+time\s+total\s+%total\s+%time\s+avg\n\n/)
      expect(output).to match(/fail\s+\d{2}:\d{2}\.\d{3}\s+1\s+/)
      expect(output).to match(/pass\s+\d{2}:\d{2}\.\d{3}\s+2\s+/)
      expect(output).to match(/__unknown__\s+\d{2}:\d{2}\.\d{3}\s+1\s+/)
    end

    specify "html report" do
      output = run_rspec("tag_prof", env: {"TAG_PROF" => "type", "TAG_PROF_FORMAT" => "html"})

      expect(output).to include("TagProf report generated:")

      expect(File.exist?("tmp/test_prof/tag-prof.html")).to eq true
    end

    context "with events" do
      specify "it works", :aggregate_failures do
        output = run_rspec(
          "tag_prof",
          env: {"TAG_PROF" => "type", "TAG_PROF_EVENT" => "test.event,test.event2"}
        )

        expect(output).to include("TagProf report for type")
        expect(output).to match(/type\s+time\s+test\.event\s+test.event2\s+total\s+%total\s+%time\s+avg\n\n/)
        expect(output).to match(/fail\s+\d{2}:\d{2}\.\d{3}\s+00:23.000\s+00:00.000\s+1\s+/)
        expect(output).to match(/pass\s+\d{2}:\d{2}\.\d{3}\s+00:12.420\s+00:14.041\s+2\s+/)
        expect(output).to match(/__unknown__\s+\d{2}:\d{2}\.\d{3}\s+00:00.000\s+00:00.000\s+1\s+/)
      end
    end
  end

  context "minitest" do
    subject(:output) { run_minitest(path, env: env, chdir: chdir) }
    let(:path) { "tag_prof" }
    let(:env) { {"TAG_PROF" => "type"} }
    let(:chdir) { nil }

    it "includes tag prof report" do
      expect(output).to include("TagProf report for type")
    end

    it "includes tag prof report headers" do
      expect(output).to match(/type\s+time\s+total\s+%total\s+%time\s+avg\n\n/)
    end

    context "when test suite is run from test file directory" do
      it "includes total time spent and number of files tested for integrations directory" do
        expect(output).to match(/integrations\s+\d{2}:\d{2}\.\d{3}\s+1\s+/)
      end
    end

    context "when test suite is run from app root directory" do
      let(:chdir) { File.expand_path("") }
      let(:path) { "spec/integrations/fixtures/minitest/tag_prof" }

      it "includes total time spent and number of files tested for integrations directory" do
        expect(output).to match(/integrations\s+\d{2}:\d{2}\.\d{3}\s+1\s+/)
      end
    end

    context "when test suite is run with event_prof" do
      let(:env) { {"TAG_PROF" => "type", "TAG_PROF_EVENT" => "test.event"} }
      it "includes event name in tag prof report headers" do
        expect(output).to match(/test.event/)
      end

      it "includes event time in data reported for integrations directory " do
        expect(output).to match(/integrations\s+\d{2}:\d{2}\.\d{3}\s+\d{2}:\d{2}\.\d{3}\s+1\s+/)
      end
    end

    context "when report format is HTML" do
      let(:env) { {"TAG_PROF" => "type", "TAG_PROF_FORMAT" => "html"} }

      it "generates an html report and gives its location" do
        output = run_rspec("tag_prof", env: env)

        expect(output).to include("TagProf report generated:")
        expect(File.exist?("tmp/test_prof/tag-prof.html")).to eq true
      end
    end

    context "when root test directory is not named 'test' or 'spec'" do
      let(:path) { "tmp/subdirectory_not_found" }
      let(:chdir) { File.expand_path("") }

      before do
        test_content = File.read("spec/integrations/fixtures/minitest/tag_prof_fixture.rb")
        File.write("tmp/subdirectory_not_found_fixture.rb", test_content)
      end

      it "reports the statistic for the test result with an explicit error message" do
        expect(output).to match(/__unknown__/)
      end

      after do
        File.delete("tmp/subdirectory_not_found_fixture.rb")
      end
    end
  end
end
