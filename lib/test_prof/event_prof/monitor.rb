# frozen_string_literal: true

module TestProf
  module EventProf
    # Wrap methods with instrumentation
    module Monitor
      class << self
        def call(mod, event, *mids)
          patch = Module.new do
            mids.each do |mid|
              module_eval <<~SRC, __FILE__, __LINE__ + 1
                def #{mid}(*)
                  TestProf::EventProf.instrumenter.instrument(
                    '#{event}'
                  ) { super }
                end
              SRC
            end
          end

          mod.prepend(patch)
        end
      end
    end
  end
end
