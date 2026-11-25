# frozen_string_literal: true

describe TestProf::EventProf::Monitor::TopLevelTracker do
  let(:instrumenter) do
    Class.new do
      attr_reader :events

      def initialize
        @events = []
      end

      def instrument(event, payload = nil)
        @events << [event, payload]
        yield
      end
    end.new
  end

  before do
    allow(TestProf::EventProf).to receive(:instrumenter).and_return(instrumenter)
  end

  let!(:tracker) { described_class.new("test.top_level") }

  it "instruments only top-level calls on the initializing thread" do
    result = tracker.track(:outer) do
      tracker.track(:inner) { :value }
    end

    expect(result).to eq(:value)
    expect(instrumenter.events).to eq([["test.top_level", :outer]])
  end

  it "instruments top-level calls on a different thread without crashing" do
    result = Thread.new do
      tracker.track(:outer) do
        tracker.track(:inner) { :from_thread }
      end
    end.value

    expect(result).to eq(:from_thread)
    expect(instrumenter.events).to eq([["test.top_level", :outer]])
  end

  it "resets depth on a different thread after an exception" do
    result = Thread.new do
      begin
        tracker.track(:first) { raise "boom" }
      rescue RuntimeError
        # expected
      end

      tracker.track(:second) { :recovered }
    end.value

    expect(result).to eq(:recovered)
    expect(instrumenter.events).to eq([
      ["test.top_level", :first],
      ["test.top_level", :second]
    ])
  end

  it "instruments top-level calls inside a separate Fiber" do
    result = Fiber.new do
      tracker.track(:outer) do
        tracker.track(:inner) { :from_fiber }
      end
    end.resume

    expect(result).to eq(:from_fiber)
    expect(instrumenter.events).to eq([["test.top_level", :outer]])
  end
end
