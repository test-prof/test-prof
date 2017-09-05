# frozen_string_literal: true

require "spec_helper"

describe "FactoryDoctor" do
  context "RSpec integration" do
    it "works when there are bad examples", :aggregate_failures do
      output = run_rspec('factory_doctor', env: { 'FDOC' => '1' })

      expect(output).to include("FactoryDoctor report")
      expect(output).to include("Total (potentially) bad examples: 3")
      expect(output).to match(/Total wasted time: \d{2}:\d{2}\.\d{3}/)

      expect(output).to include("User (./factory_doctor_fixture.rb:7)")
      expect(output).to include("generates random names (./factory_doctor_fixture.rb:10) – 2 records created")
      expect(output).to include("validates name (./factory_doctor_fixture.rb:15) – 1 record created")
      expect(output).to include("clones (./factory_doctor_fixture.rb:25) – 1 record created")
      expect(output).not_to include("is ignored")
      expect(output).not_to include("creates and reloads user")
    end

    it "print message when no bad examples", :aggregate_failures do
      output = run_rspec('factory_doctor', env: { 'FDOC' => '1', 'SPEC_OPTS' => '-e "is ignored"' })

      expect(output).to include("FactoryDoctor enabled")
      expect(output).to include('FactoryDoctor says: "Looks good to me!"')
    end

    context "with RStamp" do
      before do
        FileUtils.cp(
          File.expand_path("../../integrations/fixtures/rspec/factory_doctor_fixture.rb", __FILE__),
          File.expand_path("../../integrations/fixtures/rspec/factory_doctor_stamp_fixture.rb", __FILE__)
        )
      end

      after do
        FileUtils.rm(
          File.expand_path("../../integrations/fixtures/rspec/factory_doctor_stamp_fixture.rb", __FILE__)
        )
      end

      specify "it works", :aggregate_failures do
        output = run_rspec(
          'factory_doctor_stamp',
          env: { 'FDOC' => '1', 'FDOC_STAMP' => 'fd_ignore' }
        )

        expect(output).to include("5 examples, 0 failures")

        expect(output).to include("FactoryDoctor report")
        expect(output).to include("Total (potentially) bad examples: 3")

        expect(output).to include("RSpec Stamp results")
        expect(output).to include("Total patches: 3")
        expect(output).to include("Total files: 1")
        expect(output).to include("Failed patches: 0")
        expect(output).to include("Ignored files: 0")

        output2 = run_rspec(
          'factory_doctor_stamp',
          env: { 'FDOC' => '1' }
        )

        expect(output2).to include("5 examples, 0 failures")
        expect(output2).to include('FactoryDoctor says: "Looks good to me!"')
      end
    end
  end
end
