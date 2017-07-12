# frozen_string_literal: true

# Register FactoryDoctor listener
TestProf.activate('FPROF') do
  RSpec.configure do |config|
    listener = TestProf::FactoryProf::RSpecListener.new

    config.reporter.register_listener(
      listener, *TestProf::FactoryProf::RSpecListener::NOTIFICATIONS
    )

    config.after(:suite) { listener.print }
  end
end
