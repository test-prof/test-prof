# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "test-prof"

TestProf.config.output = StringIO.new

RSpec.configure do |config|
  config.mock_with :rspec

  config.order = :random
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  config.before(:suite) do
    FileUtils.mkdir_p("tmp")
  end

  config.before(:each) do
    allow(TestProf).to receive(:require).and_return(true)
  end

  config.after(:suite) do
    FileUtils.rm_rf("tmp")
  end
end
