# frozen_string_literal: true

require "test_prof/ext/string_strip_heredoc"

module TestProf
  module EventProf
    # Wrap methods with instrumentation
    module Monitor
      using StringStripHeredoc

      class << self
        def call(mod, event, *mids)
          patch = Module.new do
            mids.each do |mid|
              module_eval <<-SRC.strip_heredoc, __FILE__, __LINE__
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
