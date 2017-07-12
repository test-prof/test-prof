# frozen_string_literal: true

require "spec_helper"

describe "FactoryProf" do
  specify "RSpec integration", :aggregate_failures do
    output = run_rspec('factory_prof', env: { 'FPROF' => '1' })

    expect(output).to include("FactoryProf enabled (simple mode)")

    expect(output).to include("Factories usage")
    expect(output).to match(/total\s+top\-level\s+name\n\n\s+8\s+4\s+user\n\s+5\s+3\s+post/)
  end
end
