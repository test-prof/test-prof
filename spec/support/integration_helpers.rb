# frozen_string_literal: true

module IntegrationHelpers
  def run_rspec(path, chdir: nil, success: true, env: {})
    output, status = Open3.capture2(
      env,
      "bundle exec rspec #{path}_fixture.rb",
      chdir: chdir || File.expand_path("../../integrations/fixtures/rspec", __FILE__)
    )
    expect(status).to be_success, "Test #{path} failed with: #{output}" if success
    output
  end

  def run_rspec_with_clean_env(path, chdir: nil, success: true, env: {})
    output, status = Bundler.with_clean_env do
      Open3.capture2(
        env,
        "bundle exec rspec #{path}_fixture.rb",
        chdir: chdir || File.expand_path("../../integrations/fixtures/rspec", __FILE__)
      )
    end
    expect(status).to be_success, "Test #{path} failed with: #{output}" if success
    output
  end

  def run_minitest(path, chdir: nil, success: true, env: {})
    output, status = Open3.capture2(
      env,
      "bundle exec ruby #{path}_fixture.rb",
      chdir: chdir || File.expand_path("../../integrations/fixtures/minitest", __FILE__)
    )
    expect(status).to be_success, "Test #{path} failed with: #{output}" if success
    output
  end

  def gemfile_name(name)
    if RUBY_PLATFORM == "java"
      "gemfiles/#{name}_jruby.gemfile"
    elsif RUBY_VERSION.start_with?("2.3", "2.4")
      "gemfiles/#{name}_default.gemfile"
    elsif RUBY_VERSION.start_with?("2.2")
      "gemfiles/#{name}_activerecord42.gemfile"
    else
      "gemfiles/#{name}_railsmaster.gemfile"
    end
  end
end
