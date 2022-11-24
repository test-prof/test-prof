# frozen_string_literal: true

module TestProf
  module BeforeAll
    module Adapters
      # ActiveRecord adapter for `before_all`
      module ActiveRecord
        class << self
          def all_connection_classes
            @all_connection_classes ||= [::ActiveRecord::Base] + ::ActiveRecord::Base.descendants.select do |descendant|
              descendant&.connection_class?
            end.compact
          end

          def begin_transaction
            all_connection_classes.each do |connection_class|
              connection_class.connection.begin_transaction(joinable: false)
            end
          end

          def rollback_transaction
            all_connection_classes.each do |connection_class|
              if connection_class.connection.open_transactions.zero?
                warn "!!! before_all transaction has been already rollbacked and " \
                      "could work incorrectly"
                next
              end
              connection_class.connection.rollback_transaction
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

    # avoid instance variable collisions with cats
    PREFIX_RESTORE_LOCK_THREAD = "@😺"

    configure do |config|
      # Make sure ActiveRecord uses locked thread.
      # It only gets locked in `before` / `setup` hook,
      # thus using thread in `before_all` (e.g. ActiveJob async adapter)
      # might lead to leaking connections
      config.before(:begin) do
        next unless ::ActiveRecord::Base.connection.pool.respond_to?(:lock_thread=)
        instance_variable_set("#{PREFIX_RESTORE_LOCK_THREAD}_orig_lock_thread", ::ActiveRecord::Base.connection.pool.instance_variable_get(:@lock_thread)) unless instance_variable_defined? "#{PREFIX_RESTORE_LOCK_THREAD}_orig_lock_thread"
        ::ActiveRecord::Base.connection.pool.lock_thread = true
      end

      config.after(:rollback) do
        next unless ::ActiveRecord::Base.connection.pool.respond_to?(:lock_thread=)
        ::ActiveRecord::Base.connection.pool.lock_thread = instance_variable_get("#{PREFIX_RESTORE_LOCK_THREAD}_orig_lock_thread")
      end
    end
  end
end
