# frozen_string_literal: true

module TestProf
  module BeforeAll
    def self.configure
    end
  end
end

require "test_prof/before_all/adapters/active_record"

describe "TestProf::BeforeAll::Adapters::ActiveRecord" do
  let(:connection_class_1) { ActiveRecord::Base }
  let(:connection_1) { connection_class_1.connection }

  let(:connection_class_2) { ActiveRecord::Base }
  let(:connection_2) { connection_class_2.connection }

  before do
    allow(ActiveRecord::Base).to receive(:descendants).and_return([connection_class_2])

    allow(connection_class_2).to receive(:connection_class?).and_return(true)
    allow(connection_class_2).to receive(:connection).and_return(connection_2)
  end

  describe ".begin_transaction" do
    subject { ::TestProf::BeforeAll::Adapters::ActiveRecord.begin_transaction }

    it "calls begin_transaction on all available connections" do
      expect(connection_1).to receive(:begin_transaction).with(joinable: false)
      expect(connection_2).to receive(:begin_transaction).with(joinable: false)

      subject
    end
  end

  describe ".rollback_transaction" do
    subject { ::TestProf::BeforeAll::Adapters::ActiveRecord.rollback_transaction }

    context "when not all connections have started a transaction" do
      before do
        # Ensure no transactions are open due to randomization of specs
        connection_1.rollback_transaction unless connection_1.open_transactions.zero?
        connection_2.rollback_transaction unless connection_2.open_transactions.zero?
        connection_2.begin_transaction
      end

      it "warns when connection does not have open transaction" do
        expect { subject }.to output(
          "!!! before_all transaction has been already rollbacked and could work incorrectly\n"
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
