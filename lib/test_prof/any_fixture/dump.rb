# frozen_string_literal: true

require "test_prof/any_fixture/dump/digest"

require "set"

module TestProf
  module AnyFixture
    MODIFY_RXP = /^(INSERT INTO|UPDATE|DELETE FROM) ([\S]+)/i.freeze
    ANY_FIXTURE_RXP = /\-\- any_fixture:dump/.freeze

    class Dump
      class Subscriber
        attr_reader :path, :tmp_path

        def initialize(path, adapter)
          @path = path
          @adapter = adapter
          @tmp_path = path + ".tmp"
          @reset_pk = Set.new
          @file = File.open(tmp_path, "w")
        end

        def start(_event, _id, payload)
          matches = payload.fetch(:sql).match(MODIFY_RXP)
          return unless matches

          reset_pk!(matches[2]) if /insert/i.match?(matches[1])
        end

        def finish(_event, _id, payload)
          sql = payload.fetch(:sql)
          return unless trackable_sql?(sql)

          binds = payload[:binds].dup
          sql = sql.gsub(/(\?|\$\d+)/) { ActiveRecord::Base.connection.quote(binds.shift) }

          sql.tr!("\n", " ")

          file.write(sql + ";\n")
        end

        def commit
          file.close

          FileUtils.mv(tmp_path, path)
        end

        private

        attr_reader :file, :reset_pk, :adapter

        def reset_pk!(table_name)
          return if /sqlite_sequence/.match?(table_name)

          return if reset_pk.include?(table_name)

          adapter.reset_sequence!(table_name, AnyFixture.config.dump_sequence_start)
          reset_pk << table_name
        end

        def trackable_sql?(sql)
          sql.match?(MODIFY_RXP) || sql.match?(ANY_FIXTURE_RXP) || sql.match?(AnyFixture.config.dump_matching_queries)
        end
      end

      attr_reader :subscriber, :path

      def initialize(name, watch: [])
        digest = Digest.call(*watch)

        @path = build_path(name, digest)

        @adapter =
          case ActiveRecord::Base.connection.adapter_name
          when /sqlite/i
            require "test_prof/any_fixture/dump/sqlite"
            SQLite.new
          when /postgresql/i
            require "test_prof/any_fixture/dump/postgresql"
            PostgreSQL.new
          else
            raise ArgumentError,
              "Your current database adapter (#{ActiveRecord::Base.connection.adapter_name}) " \
              "is currently not supported. So far, we only support SQLite and PostgreSQL"
          end

        @subscriber = Subscriber.new(path, adapter)
      end

      def exists?
        File.exist?(path)
      end

      def load
        return import_via_active_record if AnyFixture.config.import_dump_via_active_record?

        adapter.import(path) || import_via_active_record
      end

      def commit!
        subscriber.commit
      end

      def within_prepared_env(setup: nil, teardown: nil)
        setup_dump_env(setup)
        yield
      ensure
        teardown_dump_env(teardown)
      end

      private

      attr_reader :adapter

      def import_via_active_record
        conn = ActiveRecord::Base.connection

        File.open(path).each_line do |query|
          next if query.empty?

          conn.execute query
        end
      end

      def build_path(name, digest)
        dir = TestProf.artifact_path(
          File.join(AnyFixture.config.dumps_dir)
        )

        FileUtils.mkdir_p(dir)

        File.join(dir, "#{name}-#{digest}.sql")
      end

      def setup_dump_env(callback = nil)
        # First, call config-defined setup callbacks
        AnyFixture.config.setup_dump_env.each(&:call)
        # Then, adapter-defined callbacks
        adapter.setup_env
        # Finally, user-provided callback
        callback&.call
      end

      def teardown_dump_env(callback = nil)
        # The order is vice versa to setup
        callback&.call
        adapter.teardown_env
        AnyFixture.config.teardown_dump_env.each(&:call)
      end
    end
  end
end
