# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require_relative "../../support/ar_models"
require_relative "../../support/transactional_context"
require "timecop"
require "test-prof"

User.after_create { sleep 0.01 }

Timecop.freeze

RSpec.configure do |config|
  config.include TestProf::FactoryBot::Syntax::Methods
end

describe User, :transactional do
  it "create one" do
    expect(create(:user)).to be_persisted
  end

  it "create two" do
    expect(create_pair(:user).size).to eq 2
  end
end
