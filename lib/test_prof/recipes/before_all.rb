# frozen_string_literal: true

module BeforeAll
  def before_all(&block)
    raise ArgumentError, "Block is required!" unless block_given?

    before(:all) do
      ActiveRecord::Base.connection.begin_transaction(joinable: false)
      instance_eval(&block)
    end

    after(:all) do
      ActiveRecord::Base.connection.rollback_transaction
    end
  end
end
