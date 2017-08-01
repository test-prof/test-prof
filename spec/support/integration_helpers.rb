# frozen_string_literal: true

module IntegrationHelpers
  def run_rspec(path, success: true, env: {})
    output, status = Open3.capture2(
      env,
      "rspec #{path}_fixture.rb",
      chdir: File.expand_path("../../integrations/fixtures/rspec", __FILE__)
    )
    expect(status).to be_success if success
    output
  end

  def run_minitest(path, success: true, env: {})
    output, status = Open3.capture2(
      env,
      "ruby #{path}_fixture.rb",
      chdir: File.expand_path("../../integrations/fixtures/minitest", __FILE__)
    )
    expect(status).to be_success if success
    output
  end
end
