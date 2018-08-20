# frozen_string_literal: true

module TestProf
  # Forces ActiveRecord to use the same connection between threads
  module ActiveRecordSharedConnection # :nodoc: all
    class << self
      attr_reader :connection

      def enable!
        self.connection = ActiveRecord::Base.connection
      end

      def disable!
        self.connection = nil
      end

      def ignore
        raise ArgumentError, "Block is required" unless block_given?

        @ignores ||= []

        ignores << Proc.new
      end

      def ignored?(config)
        !ignores.nil? && ignores.any? { |clbk| clbk.call(config) }
      end

      private

      attr_reader :ignores

      def connection=(conn)
        @connection = conn
        connection.singleton_class.prepend Connection
        connection
      end
    end

    module Connection
      def shared_lock
        @shared_lock ||= Mutex.new
      end

      def exec_cache(*)
        shared_lock.synchronize { super }
      end

      def exec_no_cache(*)
        shared_lock.synchronize { super }
      end

      def execute(*)
        shared_lock.synchronize { super }
      end
    end

    module Ext
      def connection
        return super if ActiveRecordSharedConnection.ignored?(connection_config)
        ActiveRecordSharedConnection.connection || super
      end
    end
  end
end

ActiveSupport.on_load(:active_record) do
  TestProf::ActiveRecordSharedConnection.enable!
  ActiveRecord::Base.singleton_class.prepend TestProf::ActiveRecordSharedConnection::Ext
end
