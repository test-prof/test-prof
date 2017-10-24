# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)

$LOAD_PATH.delete_if { |p| (p =~ /factory_girl/) || (p =~ /factory_bot/) }

require "test-prof"

context "when no factory_bot installed" do
  it "do nothing" do
    expect { FactoryGirl.create(:user) }.to raise_error(NameError)
    expect { FactoryBot.create(:user) }.to raise_error(NameError)
    expect(true).to eq true
  end
end
