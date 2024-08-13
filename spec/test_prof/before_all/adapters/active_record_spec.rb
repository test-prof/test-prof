# frozen_string_literal: true

module TestProf
  module BeforeAll
    def self.configure
    end
  end
end

require "test_prof/before_all/adapters/active_record"

describe TestProf::BeforeAll::Adapters::ActiveRecord do
  context "when using single database", skip: (multi_db? ? "Using multiple databases" : nil) do
    let(:connection_pool) { ApplicationRecord.connection_pool }
    let(:connection) { connection_pool.lease_connection }

    describe ".begin_transaction" do
      subject { ::TestProf::BeforeAll::Adapters::ActiveRecord.begin_transaction }

      if ::ActiveRecord::Base.connection.pool.respond_to?(:pin_connection!)
        it "calls pin_connection! on all available connections" do
          expect(connection_pool).to receive(:pin_connection!).with(true)

          subject
        end
      else
        it "calls begin_transaction on all available connections" do
          expect(connection).to receive(:begin_transaction).with(a_hash_including(joinable: false))

          subject
        end
      end
    end

    describe ".rollback_transaction" do
      subject { ::TestProf::BeforeAll::Adapters::ActiveRecord.rollback_transaction }

      if ::ActiveRecord::Base.connection.pool.respond_to?(:pin_connection!)
        it "calls unpin_connection! on all available connections" do
          expect(connection_pool).to receive(:unpin_connection!)

          subject
        end
      else
        context "when not all connections have started a transaction" do
          before do
            # Ensure no transactions are open due to randomization of specs
            connection.rollback_transaction unless connection.open_transactions.zero?
          end

          it "warns when connection does not have open transaction" do
            expect { subject }.to output(
              /!!! before_all transaction has been already rollbacked and could work incorrectly\n/
            ).to_stderr
          end
        end

        context "when the connection is a transaction" do
          before do
            connection.begin_transaction
            allow(connection).to receive(:rollback_transaction).and_call_original
          end

          it "calls rollback_transaction on all available connections" do
            subject
            expect(connection).to have_received(:rollback_transaction)
          end
        end
      end
    end
  end

  context "when using multiple databases", skip: ((!multi_db?) ? "Using single database" : nil) do
    let(:connection_pool_list) { [ApplicationRecord, CommentsRecord] }
    let(:connection_1) { connection_pool_list.first.connection }
    let(:connection_2) { connection_pool_list.second.connection }

    describe ".begin_transaction" do
      subject { ::TestProf::BeforeAll::Adapters::ActiveRecord.begin_transaction }

      it "calls begin_transaction on all available connections" do
        expect(connection_1).to receive(:begin_transaction).with(a_hash_including(joinable: false))
        expect(connection_2).to receive(:begin_transaction).with(a_hash_including(joinable: false))

        subject
      end
    end

    describe ".rollback_transaction" do
      subject { ::TestProf::BeforeAll::Adapters::ActiveRecord.rollback_transaction }

      if ::ActiveRecord::Base.connection.pool.respond_to?(:pin_connection!)
        it "calls #unpin_connection! on each connection" do
          expect(connection_pool_list.first.connection_pool).to receive(:unpin_connection!)
          expect(connection_pool_list.last.connection_pool).to receive(:unpin_connection!)

          subject
        end
      else
        context "when not all connections have started a transaction" do
          before do
            # Ensure no transactions are open due to randomization of specs
            connection_1.rollback_transaction unless connection_1.open_transactions.zero?
            connection_2.rollback_transaction unless connection_2.open_transactions.zero?
            connection_2.begin_transaction
          end

          it "warns when connection does not have open transaction" do
            expect { subject }.to output(
              /!!! before_all transaction has been already rollbacked and could work incorrectly\n/
            ).to_stderr
          end
        end

        context "when the connection is a transaction" do
          before do
            connection_1.begin_transaction
            connection_2.begin_transaction
          end

          it "calls rollback_transaction on all available connections" do
            expect(connection_1).to receive(:rollback_transaction)
            expect(connection_2).to receive(:rollback_transaction)

            subject
          end
        end
      end
    end
  end
end
