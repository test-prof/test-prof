module InstrumenterStub
  class << self
    def subscribe(event, &block)
      listeners[event] = block
    end

    def notify(event, time)
      listeners[event].call(time)
    end

    private

    def listeners
      @listeners ||= {}
    end
  end
end
