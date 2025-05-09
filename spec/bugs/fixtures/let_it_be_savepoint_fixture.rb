# frozen_string_literal: true

require "action_controller/railtie"
require "action_view/railtie"
require "active_record/railtie"
require "rspec/rails"

require_relative "../../support/ar_models"

RSpec.configure do |config|
  if config.respond_to?(:fixture_paths)
    config.fixture_paths = [File.join(__dir__, "fixtures")]
  else
    config.fixture_path = File.join(__dir__, "fixtures")
  end
  config.use_transactional_fixtures = true
end

require "test_prof/recipes/rspec/let_it_be"

RSpec.configure do |config|
  config.include TestProf::FactoryBot::Syntax::Methods
end

describe "let_it_be no-op" do
  context "without db calls" do
    let_it_be(:foo) { 1 }

    specify { expect(1).to eq 1 }
    specify { expect(foo).to eq 1 }
  end
end
