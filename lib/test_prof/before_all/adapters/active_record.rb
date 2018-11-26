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
  end
end
