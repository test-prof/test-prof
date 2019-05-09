# frozen_string_literal: true

if ::ActiveRecord::VERSION::MAJOR < 4
  require "test_prof/ext/active_record_3"
  using TestProf::ActiveRecord3Transactions
end

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
