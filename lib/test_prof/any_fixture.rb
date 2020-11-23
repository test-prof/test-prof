# frozen_string_literal: true

require "test_prof/ext/float_duration"
require "test_prof/any_fixture/dump"

module TestProf
  # Make DB fixtures from blocks.
  module AnyFixture
    INSERT_RXP = /^INSERT INTO ([\S]+)/.freeze

    using FloatDuration

    # AnyFixture configuration
    class Configuration
      attr_accessor :reporting_enabled, :dumps_dir
      attr_reader :default_dump_watch_paths

      alias reporting_enabled? reporting_enabled

      def initialize
        @reporting_enabled = ENV["ANYFIXTURE_REPORT"] == "1"
        @dumps_dir = "any_dumps"
        @default_dump_watch_paths = %w[
          db/schema.rb
          db/structure.sql
        ]
      end
    end

    class Cache # :nodoc:
      attr_reader :store, :stats

      def initialize
        @store = {}
        @stats = {}
      end

      def fetch(key)
        if store.key?(key)
          stats[key][:hit] += 1
          return store[key]
        end

        return unless block_given?

        ts = TestProf.now
        store[key] = yield
        stats[key] = {time: TestProf.now - ts, hit: 0}
        store[key]
      end

      def clear
        store.clear
        stats.clear
      end
    end

    class << self
      include Logging

      def config
        @config ||= Configuration.new
      end

      def configure
        yield config
      end

      # Backward compatibility
      def reporting_enabled=(val)
        warn "AnyFixture.reporting_enabled is deprecated. Use AnyFixture.config.reporting_enabled instead"
        config.reporting_enabled = val
      end

      def reporting_enabled
        warn "AnyFixture.reporting_enabled is deprecated. Use AnyFixture.config.reporting_enabled instead"
        config.reporting_enabled
      end

      alias reporting_enabled? reporting_enabled

      # Register a block of code as a fixture,
      # returns the result of the block execution
      def register(id)
        cache.fetch(id) do
          ActiveSupport::Notifications.subscribed(method(:subscriber), "sql.active_record") do
            yield
          end
        end
      end

      # Create and register new SQL dump.
      # Use `watch` to provide additional paths to watch for
      # dump re-generation
      def register_dump(name, **options)
        register("sql/#{name}") do
          dump = Dump.new(name, called_from: caller_locations(1, 1), **options)

          next dump.load if dump.exists?

          subscriber = ActiveSupport::Notifications.subscribe("sql.active_record", dump.subscriber)

          res = yield

          dump.commit!

          res
        ensure
          ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
        end
      end

      # Clean all affected tables (but do not reset cache)
      def clean
        disable_referential_integrity do
          tables_cache.keys.reverse_each do |table|
            ActiveRecord::Base.connection.execute %(
              DELETE FROM #{table}
            )
          end
        end
      end

      # Reset all information and clean tables
      def reset
        clean
        tables_cache.clear
        cache.clear
      end

      def subscriber(_event, _start, _finish, _id, data)
        matches = data.fetch(:sql).match(INSERT_RXP)
        return unless matches

        table_name = matches[1]

        return if /sqlite_sequence/.match?(table_name)

        tables_cache[table_name] = true
      end

      def report_stats
        if cache.stats.empty?
          log :info, "AnyFixture has not been used"
          return
        end

        msgs = []

        msgs <<
          <<~MSG
            AnyFixture usage stats:
          MSG

        first_column = cache.stats.keys.map(&:size).max + 2

        msgs << format(
          "%#{first_column}s  %12s  %9s  %12s",
          "key", "build time", "hit count", "saved time"
        )

        msgs << ""

        total_spent = 0.0
        total_saved = 0.0
        total_miss = 0.0

        cache.stats.to_a.sort_by { |(_, v)| -v[:hit] }.each do |(key, stats)|
          total_spent += stats[:time]

          saved = stats[:time] * stats[:hit]

          total_saved += saved

          total_miss += stats[:time] if stats[:hit].zero?

          msgs << format(
            "%#{first_column}s  %12s  %9d  %12s",
            key, stats[:time].duration, stats[:hit],
            saved.duration
          )
        end

        msgs <<
          <<~MSG

            Total time spent: #{total_spent.duration}
            Total time saved: #{total_saved.duration}
            Total time wasted: #{total_miss.duration}
          MSG

        log :info, msgs.join("\n")
      end

      private

      def cache
        @cache ||= Cache.new
      end

      def tables_cache
        @tables_cache ||= {}
      end

      def disable_referential_integrity
        connection = ActiveRecord::Base.connection
        return yield unless connection.respond_to?(:disable_referential_integrity)
        connection.disable_referential_integrity { yield }
      end
    end
  end
end
