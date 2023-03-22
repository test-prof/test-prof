# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
begin
  require "debug" unless ENV["CI"]
rescue LoadError
end

require "open3"

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec

  config.order = :random
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  config.example_status_persistence_file_path = "tmp/.rspec-status" if
    config.respond_to?(:example_status_persistence_file_path=)

  config.define_derived_metadata(file_path: %r{/spec/integrations/}) do |metadata|
    metadata[:type] = :integration
  end

  config.include IntegrationHelpers, type: :integration

  config.before(:suite) do
    FileUtils.mkdir_p(TestProf.config.output_dir)
  end

  config.before(:each) do
    allow(TestProf).to receive(:require).and_return(true)
    # Clear global configuration
    TestProf.remove_instance_variable(:@config) if
      TestProf.instance_variable_defined?(:@config)
    TestProf.config.output = StringIO.new
  end

  config.after(:suite) do
    FileUtils.rm_rf(TestProf.config.output_dir)
  end
end
