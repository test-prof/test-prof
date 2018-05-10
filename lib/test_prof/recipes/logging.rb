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
      logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = Logger.new(STDOUT)
      ex.run
      ActiveRecord::Base.logger = logger
    end
  end
end

TestProf.activate("LOG", "all") do
  ActiveSupport::LogSubscriber.logger =
    Rails.logger =
      ActiveRecord::Base.logger = Logger.new(STDOUT)
end

TestProf.activate("LOG", "ar") do
  ActiveRecord::Base.logger = Logger.new(STDOUT)
end
