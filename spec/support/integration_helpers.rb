# frozen_string_literal: true

module IntegrationHelpers
  RUBY_RUNNER = if defined?(JRUBY_VERSION)
    # See https://github.com/jruby/jruby/wiki/Improving-startup-time#bundle-exec
    "jruby -G"
  else
    "bundle exec ruby"
  end

  RSPEC_STUB = File.join(__dir__, "../../bin/rspec")

  def run_rspec(path, chdir: nil, success: true, env: {}, options: "")
    command = "#{RUBY_RUNNER} #{RSPEC_STUB} #{options} #{path}_fixture.rb"
    output, err, status = Open3.capture3(
      env,
      command,
      chdir: chdir || File.expand_path("../../integrations/fixtures/rspec", __FILE__)
    )

    if ENV["COMMAND_DEBUG"]
      puts "\n\nCOMMAND:\n#{command}\n\nOUTPUT:\n#{output}\nERROR:\n#{err}\n"
    end

    expect(status).to be_success, "Test #{path} failed with: #{output}, err: #{err}" if success
    warn output if output.match?(/warning:/i)
    output
  end

  def run_minitest(path, chdir: nil, success: true, env: {})
    command = "#{RUBY_RUNNER} #{path}_fixture.rb #{env["TESTOPTS"]}"

    output, err, status = Open3.capture3(
      env,
      command,
      chdir: chdir || File.expand_path("../../integrations/fixtures/minitest", __FILE__)
    )

    if ENV["COMMAND_DEBUG"]
      puts "\n\nCOMMAND:\n#{command}\n\nOUTPUT:\n#{output}\nERROR:\n#{err}\n"
    end

    expect(status).to be_success, "Test #{path} failed with: #{output}, err: #{err}" if success
    warn output if output.match?(/warning:/i)
    output
  end

  def run_rubocop(path, cop:)
    fullpath = File.join(__dir__, "../integrations/fixtures/rubocop", "#{path}_fixture.rb")
    test_prof_lib = File.join(__dir__, "../../lib")

    command = "rubocop -r test_prof/rubocop.rb --force-default-config --only #{cop} #{fullpath} 2>&1"

    output, err, _status = Open3.capture3(
      {"RUBYOPT" => "-I#{test_prof_lib}"},
      command
    )

    if ENV["COMMAND_DEBUG"]
      puts "\n\nCOMMAND:\n#{command}\n\nOUTPUT:\n#{output}\nERROR:\n#{err}\n"
    end

    warn output if output.match?(/warning:/i)
    output
  end
end
