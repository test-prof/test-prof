# frozen_string_literal: true

module TestProf
  # Add missing `begin_transaction` and `rollback_transaction` methods
  module ActiveRecord3Transactions
    refine ::ActiveRecord::ConnectionAdapters::AbstractAdapter do
      def begin_transaction(joinable: true)
        if open_transactions > 0
          increment_open_transactions
          create_savepoint
        else
          begin_db_transaction
        end
        self.transaction_joinable = joinable
      end

      def rollback_transaction(*)
        if open_transactions > 1
          rollback_to_savepoint
        else
          rollback_db_transaction
        end
        decrement_open_transactions
      end
    end
  end
end
