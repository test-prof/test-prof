# frozen_string_literal: true

module TestProf::EventProf
  module Instrumentations
    # Wrapper over ActiveSupport::Notifications
    module ActiveSupport
      def self.subscribe(event)
        raise ArgumentError, 'Block is required!' unless block_given?

        ::ActiveSupport::Notifications.subscribe(event) do |_event, start, finish, *_args|
          yield (finish - start)
        end
      end
    end
  end
end
