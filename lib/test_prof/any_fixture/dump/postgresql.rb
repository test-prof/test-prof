# frozen_string_literal: true

module TestProf
  module AnyFixture
    class Dump
      module PostgreSQL
        module_function

        def reset_sequence!(table_name, start)
          conn = ActiveRecord::Base.connection

          _pk, sequence = conn.pk_and_sequence_for(table_name)
          return unless sequence

          sequence_name = "#{sequence.schema}.#{sequence.identifier}"

          conn.execute <<~SQL
            ALTER SEQUENCE #{sequence_name} RESTART WITH #{start};
          SQL
        end

        def import(path)
          # Test if psql is installed
          `psql --version`

          ActiveRecord::Base.connection.disconnect!

          conn = ActiveRecord::Base.connection

          tasks = ActiveRecord::Tasks::PostgreSQLDatabaseTasks.new(conn.pool.spec.config.with_indifferent_access)

          tasks.structure_load(path, "--output=/dev/null")

          true
        rescue Errno::ENOENT
          false
        ensure
          # Re-connect back
          ActiveRecord::Base.connection.reconnect!
        end
      end
    end
  end
end
