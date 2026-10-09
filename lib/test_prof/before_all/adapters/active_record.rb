# frozen_string_literal: true

module TestProf
  module BeforeAll
    module Adapters
      # ActiveRecord adapter for `before_all`
      module ActiveRecord
        POOL_ARGS = ((::ActiveRecord::VERSION::MAJOR > 6) ? [:writing] : []).freeze

        class << self
          if ::ActiveRecord::Base.connection.pool.respond_to?(:pin_connection!)
            def begin_transaction
              # don't rely on connection_handler.connection_pool_list,
              # track pinned pools ourselves
              # see https://github.com/rails/rails/pull/58489
              pinned_pools = []
              pinned_pools_stack.push(pinned_pools)
              subscribe! if pinned_pools_stack.size == 1

              ::ActiveRecord::Base.connection_handler.connection_pool_list(:writing).each do |pool|
                pin_pool!(pool)
                pinned_pools << pool
              end
            end

            def rollback_transaction
              pinned_pools = pinned_pools_stack.pop
              pinned_pools&.each { |pool| unpin_pool!(pool) }
            ensure
              unsubscribe! if pinned_pools_stack.empty?
            end

            def pinned_pools_stack
              Thread.current[:before_all_pinned_pools_stack] ||= []
            end

            def subscribe!
              # notifications are not Thread-pinned, so
              # we must keep a reference to the current stack
              stack = pinned_pools_stack

              Thread.current[:before_all_connection_subscriber] = ActiveSupport::Notifications.subscribe("!connection.active_record") do |_, _, _, _, payload|
                connection_name = payload[:connection_name] if payload.key?(:connection_name)
                shard = payload[:shard] if payload.key?(:shard)
                # Use the role of the established connection, not the current one
                role = payload.fetch(:role, ::ActiveRecord::Base.current_role)
                next unless connection_name

                pool = ::ActiveRecord::Base.connection_handler.retrieve_connection_pool(connection_name, role: role, shard: shard)
                next unless pool && pool.role == :writing

                pinned_pools = stack.last
                next if pinned_pools.nil? || pinned_pools.include?(pool)

                pin_pool!(pool)
                pinned_pools << pool
              end
            end

            def unsubscribe!
              return unless Thread.current[:before_all_connection_subscriber]

              ActiveSupport::Notifications.unsubscribe(Thread.current[:before_all_connection_subscriber])
              Thread.current[:before_all_connection_subscriber] = nil
            end

            # Rails 8.2+
            if ::ActiveRecord.version >= Gem::Version.new("8.2.0.alpha")
              def pin_pool!(pool)
                pool.pin_connection!(true)
                pool.lease_connection.begin_transaction(joinable: false, _lazy: false)
              end

              def unpin_pool!(pool)
                connection = pool.lease_connection
                if connection.transaction_open?
                  connection.rollback_transaction
                else
                  warn "!!! before_all transaction has been already rollbacked and could work incorrectly"
                  connection.reset!
                end
              ensure
                pool.unpin_connection!
              end
            else
              def pin_pool!(pool)
                pool.pin_connection!(true)
              end

              def unpin_pool!(pool)
                pool.unpin_connection!
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
