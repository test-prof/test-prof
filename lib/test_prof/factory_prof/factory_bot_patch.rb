# frozen_string_literal: true

module TestProf
  module FactoryProf
    # Wrap #run method with FactoryProf tracking
    module FactoryBotPatch
      def run(strategy = @strategy)
        variation = ""

        if FactoryProf.config.include_variations?
          if @traits || @overrides
            unless @traits.empty?
              variation += @traits.sort.join(".").prepend(".")
            end

            unless @overrides.empty?
              variation += @overrides.keys.sort.to_s.gsub(/[\\":]/, "")
            end
          end
        end

        FactoryBuilders::FactoryBot.track(strategy, @name, variation: variation.to_sym) { super }
      end
    end
  end
end
