# frozen_string_literal: true

require "test_prof/factory_doctor/factory_girl_patch"

module TestProf
  # FactoryDoctor is a tool that helps you identify
  # tests that perform unnecessary database queries.
  module FactoryDoctor
    class Result # :nodoc:
      attr_reader :count, :time, :queries_count

      def initialize(count, time, queries_count)
        @count = count
        @time = time
        @queries_count = queries_count
      end

      def bad?
        count > 0 && queries_count.zero?
      end
    end

    IGNORED_QUERIES_PATTERN = %r{(
      pg_table|
      pg_attribute|
      pg_namespace|
      show\stables|
      pragma|
      sqlite_master/rollback|
      \ATRUNCATE TABLE|
      \AALTER TABLE|
      \ABEGIN|
      \ACOMMIT|
      \AROLLBACK|
      \ARELEASE|
      \ASAVEPOINT
    )}xi

    class << self
      include TestProf::Logging

      attr_reader :event
      attr_reader :count, :time, :queries_count

      # Patch factory lib, init counters
      def init(event = 'sql.active_record')
        @event = event
        reset!

        log :info, "FactoryDoctor enabled"

        # Monkey-patch FactoryGirl
        ::FactoryGirl::FactoryRunner.prepend(FactoryGirlPatch) if
          defined?(::FactoryGirl)

        subscribe!

        @stamp = ENV['FDOC_STAMP']

        RSpecStamp.config.tags = @stamp if stamp?
      end

      def stamp?
        !@stamp.nil?
      end

      def start
        reset!
        @running = true
      end

      def stop
        @running = false
      end

      def result
        Result.new(count, time, queries_count)
      end

      # Do not analyze code within the block
      def ignore
        @ignored = true
        res = yield
      ensure
        @ignored = false
        res
      end

      def within_factory(strategy)
        return yield if ignore? || !running? || (strategy != :create)

        begin
          ts = TestProf.now if @depth.zero?
          @depth += 1
          @count += 1
          yield
        ensure
          @depth -= 1

          @time += (TestProf.now - ts) if @depth.zero?
        end
      end

      private

      def reset!
        @depth = 0
        @time = 0.0
        @count = 0
        @queries_count = 0
      end

      def subscribe!
        ::ActiveSupport::Notifications.subscribe(event) do |_name, _start, _finish, _id, query|
          next if ignore? || !running? || within_factory?
          next if query[:sql] =~ IGNORED_QUERIES_PATTERN
          @queries_count += 1
        end
      end

      def within_factory?
        @depth > 0
      end

      def ignore?
        @ignored == true
      end

      def running?
        @running == true
      end
    end
  end
end

require "test_prof/factory_doctor/rspec" if defined?(RSpec::Core)
require "test_prof/factory_doctor/minitest" if defined?(Minitest::Reporters)

TestProf.activate('FDOC') do
  TestProf::FactoryDoctor.init
end
