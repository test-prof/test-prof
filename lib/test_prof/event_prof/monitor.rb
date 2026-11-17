# frozen_string_literal: true

module TestProf
  module EventProf
    # Wrap methods with instrumentation
    module Monitor
      class BaseTracker
        attr_reader :event

        def initialize(event)
          @event = event
        end

        def track(payload = nil)
          TestProf::EventProf.instrumenter.instrument(event, payload) { yield }
        end
      end

      class TopLevelTracker < BaseTracker
        attr_reader :id

        def initialize(event)
          super
          @id = :"event_prof_monitor_#{event}"
          Thread.current[id] = 0
        end

        def track(payload = nil)
          Thread.current[id] += 1
          res = nil
          begin
            res =
              if Thread.current[id] == 1
                super { yield }
              else
                yield
              end
          ensure
            Thread.current[id] -= 1
          end
          res
        end
      end

      class << self
        def call(mod, event, *mids, guard: nil, top_level: false, payload: nil)
          tracker = top_level ? TopLevelTracker.new(event) : BaseTracker.new(event)

          patch = Module.new do
            mids.each do |mid|
              define_method(mid) do |*args, **kwargs, &block|
                next super(*args, **kwargs, &block) unless guard.nil? || instance_exec(*args, **kwargs, &guard)
                pl = payload ? instance_exec(*args, **kwargs, &payload) : nil
                tracker.track(pl) { super(*args, **kwargs, &block) }
              end
            end
          end

          mod.prepend(patch)
        end
      end
    end
  end
end
