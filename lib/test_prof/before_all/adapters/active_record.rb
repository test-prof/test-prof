# frozen_string_literal: true

module TestProf
  module BeforeAll
    module Adapters
      # ActiveRecord adapter for `before_all`
      module ActiveRecord
        POOL_ARGS = ((::ActiveRecord::VERSION::MAJOR > 6) ? [:writing] : []).freeze

        class << self
          if ::ActiveRecord::Base.connection.pool.respond_to?(:pin_connection!)
            ::ActiveRecord::ConnectionAdapters::ConnectionPool.prepend(Module.new do
              # FIXME: Why `@pinned_connection = nil; super` doesn't work?
              def pin_connection!(lock_thread) # :nodoc:
                # raise "There is already a pinned connection" if @pinned_connection

                @pinned_connection = connection_lease&.connection || checkout
                # Any leased connection must be in @connections otherwise
                # some methods like #connected? won't behave correctly
                unless @connections.include?(@pinned_connection)
                  @connections << @pinned_connection
                end

                @pinned_connection.lock_thread = ActiveSupport::IsolatedExecutionState.context if lock_thread
                @pinned_connection.verify! # eagerly validate the connection
                @pinned_connection.begin_transaction joinable: false, _lazy: false
              end
            end)

            def begin_transaction
              ::ActiveRecord::Base.connection_handler.connection_pool_list(*POOL_ARGS).each do |pool|
                pool.pin_connection!(true)
              end
            end

            def rollback_transaction
              ::ActiveRecord::Base.connection_handler.connection_pool_list(*POOL_ARGS).each do |pool|
                # If it has pinned connection, we must unpin it;
                # if it has been already unpinned, just rollback
                next pool.unpin_connection! if pool.instance_variable_get(:@pinned_connection)

                connection = pool.lease_connection
                if connection.open_transactions.zero?
                  warn "!!! before_all transaction has been already rollbacked and " \
                        "could work incorrectly"
                  next
                end
                connection.rollback_transaction
              end
            end
          else
            def all_connections
              @all_connections ||= if ::ActiveRecord::Base.respond_to? :connects_to
                ::ActiveRecord::Base.connection_handler.connection_pool_list(*POOL_ARGS).filter_map { |pool|
                  begin
                    pool.connection
                  rescue *pool_connection_errors => error
                    log_pool_connection_error(pool, error)
                    nil
                  end
                }
              else
                Array.wrap(::ActiveRecord::Base.connection)
              end
            end

            def pool_connection_errors
              @pool_connection_errors ||= []
            end

            def log_pool_connection_error(pool, error)
              warn "Could not connect to pool #{pool.connection_class.name}. #{error.class}: #{error.message}"
            end

            def begin_transaction
              @all_connections = nil
              all_connections.each do |connection|
                connection.begin_transaction(joinable: false)
              end
            end

            def rollback_transaction
              all_connections.each do |connection|
                if connection.open_transactions.zero?
                  warn "!!! before_all transaction has been already rollbacked and " \
                        "could work incorrectly"
                  next
                end
                connection.rollback_transaction
              end
            end
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

    unless ::ActiveRecord::Base.connection.pool.respond_to?(:pin_connection!)
      # avoid instance variable collisions with cats
      PREFIX_RESTORE_LOCK_THREAD = "@😺"

      configure do |config|
        # Make sure ActiveRecord uses locked thread.
        # It only gets locked in `before` / `setup` hook,
        # thus using thread in `before_all` (e.g. ActiveJob async adapter)
        # might lead to leaking connections
        config.before(:begin) do
          instance_variable_set("#{PREFIX_RESTORE_LOCK_THREAD}_orig_lock_thread", ::ActiveRecord::Base.connection.pool.instance_variable_get(:@lock_thread)) unless instance_variable_defined? "#{PREFIX_RESTORE_LOCK_THREAD}_orig_lock_thread"
          ::ActiveRecord::Base.connection.pool.lock_thread = true
        end

        config.after(:rollback) do
          ::ActiveRecord::Base.connection.pool.lock_thread = instance_variable_get("#{PREFIX_RESTORE_LOCK_THREAD}_orig_lock_thread")
        end
      end
    end
  end
end
