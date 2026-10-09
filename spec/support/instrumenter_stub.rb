# frozen_string_literal: true

module InstrumenterStub
  class << self
    def subscribe(event, &block)
      listeners[event] = block
    end

    def notify(event, time, payload = nil)
      listeners[event].call(time, payload)
    end

    private

    def listeners
      @listeners ||= {}
    end
  end
end
