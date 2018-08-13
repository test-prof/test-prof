# frozen_string_literal: true

if defined?(RSpec)
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
