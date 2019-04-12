# frozen_string_literal: true

require "test_prof"

if TestProf.rspec?
  RSpec.shared_context "logging:verbose", log: true do
    around(:each) do |ex|
      *loggers = ActiveSupport::LogSubscriber.logger,
                 Rails.logger,
                 ActiveRecord::Base.logger
      ActiveSupport::LogSubscriber.logger =
        Rails.logger =
          ActiveRecord::Base.logger = Logger.new(STDOUT)
      ex.run
      ActiveSupport::LogSubscriber.logger,
      Rails.logger,
      ActiveRecord::Base.logger = *loggers
    end
  end

  RSpec.shared_context "logging:active_record", log: :ar do
    around(:each) do |ex|
      *loggers = ActiveRecord::Base.logger,
                 ActiveSupport::LogSubscriber.logger
      ActiveSupport::LogSubscriber.logger =
        ActiveRecord::Base.logger = Logger.new(STDOUT)
      ex.run
      ActiveSupport::LogSubscriber.logger,
      ActiveRecord::Base.logger = *loggers
    end
  end

  RSpec.configure do |config|
    next unless defined?(config.include_context)
    config.include_context "logging:active_record", log: :ar
    config.include_context "logging:verbose", log: true
  end
end

TestProf.activate("LOG", "all") do
  TestProf.log :info, "Rails verbose logging enabled"
  ActiveSupport::LogSubscriber.logger =
    Rails.logger =
      ActiveRecord::Base.logger = Logger.new(STDOUT)
end

TestProf.activate("LOG", "ar") do
  TestProf.log :info, "Active Record verbose logging enabled"
  ActiveSupport::LogSubscriber.logger =
    ActiveRecord::Base.logger = Logger.new(STDOUT)
end
