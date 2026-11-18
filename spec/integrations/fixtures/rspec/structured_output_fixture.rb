# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require_relative "../../../support/ar_models"
require "test-prof"

TestProf.configure do |config|
  config.output_dir = "../../../../tmp/test_prof"
end

describe "Something" do
  let(:value) { TestProf::FactoryBot.create(:user) }

  before { @value = value }

  it "works" do
    expect(@value).not_to be_nil
  end

  it "works again" do
    expect(value).not_to be_nil
  end
end
