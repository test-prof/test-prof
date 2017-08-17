# frozen_string_literal: true

module TestProf
  # Make DB fixtures from blocks.
  module AnyFixture
    INSERT_RXP = /^INSERT INTO ([\S]+)/

    class Cache # :nodoc:
      attr_reader :store

      delegate :clear, to: :store

      def initialize
        @store = {}
      end

      def fetch(key)
        return store[key] if store.key?(key)
        return unless block_given?
        store[key] = yield
      end
    end

    class << self
      # Register a block of code as a fixture,
      # returns the result of the block execution
      def register(id)
        cache.fetch(id) do
          ActiveSupport::Notifications.subscribed(method(:subscriber), "sql.active_record") do
            yield
          end
        end
      end

      # Clean all affected tables (but do not reset cache)
      def clean
        tables_cache.keys.reverse_each do |table|
          ActiveRecord::Base.connection.execute %(
            DELETE FROM #{table}
          )
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
        tables_cache[matches[1]] = true if matches
      end

      private

      def cache
        @cache ||= Cache.new
      end

      def tables_cache
        @tables_cache ||= {}
      end
    end
  end
end
