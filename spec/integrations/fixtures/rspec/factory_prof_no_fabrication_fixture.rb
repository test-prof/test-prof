# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)

$LOAD_PATH.delete_if { |p| p =~ /fabrication/ }

require "test-prof"

context "when no fabrication installed" do
  it "do nothing" do
    expect { Fabricate(:user) }.to raise_error(NameError)
    expect(true).to eq true
  end
end
