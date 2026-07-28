# frozen_string_literal: true

module TestProf::EventProf
  module Instrumentations
    # Wrapper over ActiveSupport::Notifications
    module ActiveSupport
      class Subscriber
        attr_reader :block, :started_at

        def initialize(block)
          @block = block
        end

        def start(*)
          @started_at = TestProf.now
        end

        def publish(_name, started_at, finished_at, _id, payload)
          block.call(finished_at - started_at, payload)
        end

        def finish(_name, _id, payload)
          block.call(TestProf.now - started_at, payload)
        end
      end

      class << self
        def subscribe(event, &block)
          raise ArgumentError, "Block is required!" unless block

          ::ActiveSupport::Notifications.subscribe(event, Subscriber.new(block))
        end

        def instrument(event, payload = nil)
          ::ActiveSupport::Notifications.instrument(event, payload) { yield }
        end
      end
    end
  end
end
