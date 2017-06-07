module IntegrationHelpers
  def run_rspec(path, env: {})
    output, status = Open3.capture2(
      env,
      "rspec #{path}",
      chdir: File.expand_path("../../integrations/fixtures", __FILE__)
    )
    expect(status).to be_success
    output
  end
end
