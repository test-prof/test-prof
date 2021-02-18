# frozen_string_literal: true

module TestProf
  module BeforeAll
    module Adapters
      # ActiveRecord adapter for `before_all`
      module ActiveRecord
        class << self
          def begin_transaction
            ::ActiveRecord::Base.connection.begin_transaction(joinable: false)
          end

          def rollback_transaction
            if ::ActiveRecord::Base.connection.open_transactions.zero?
              warn "!!! before_all transaction has been already rollbacked and " \
                   "could work incorrectly"
              return
            end
            ::ActiveRecord::Base.connection.rollback_transaction
          end

          def setup_fixtures(test_object)
            test_object.instance_eval do
              @@already_loaded_fixtures ||= {}
              @fixture_cache ||= {}
              config = ::ActiveRecord::Base

              if @@already_loaded_fixtures[self.class]
                @loaded_fixtures = @@already_loaded_fixtures[self.class]
              else
                @loaded_fixtures = load_fixtures(config)
                @@already_loaded_fixtures[self.class] = @loaded_fixtures
              end
            end
          end
        end
      end
    end

    configure do |config|
      # Make sure ActiveRecord uses locked thread.
      # It only gets locked in `before` / `setup` hook,
      # thus using thread in `before_all` (e.g. ActiveJob async adapter)
      # might lead to leaking connections
      config.before(:begin) do
        next unless ::ActiveRecord::Base.connection.pool.respond_to?(:lock_thread=)
        ::ActiveRecord::Base.connection.pool.lock_thread = true
      end
    end
  end
end
