# frozen_string_literal: true

require "spec_helper"

describe "FactoryDoctor" do
  specify "RSpec integration", :aggregate_failures do
    output = run_rspec('factory_doctor_rspec_fixture.rb', env: { 'FDOC' => '1' })

    expect(output).to include("FactoryDoctor report")
    expect(output).to include("Total (potentially) bad examples: 3")
    expect(output).to match(/Total wasted time: \d{2}:\d{2}\.\d{3}/)

    expect(output).to include("User (./factory_doctor_rspec_fixture.rb:7)")
    expect(output).to include("generates random names (./factory_doctor_rspec_fixture.rb:10) – 2 records created")
    expect(output).to include("validates name (./factory_doctor_rspec_fixture.rb:15) – 1 record created")
    expect(output).to include("clones (./factory_doctor_rspec_fixture.rb:25) – 1 record created")
    expect(output).not_to include("is ignored")
    expect(output).not_to include("creates and reloads user")
  end
end
