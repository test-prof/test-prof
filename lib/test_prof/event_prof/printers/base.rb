# frozen_string_literal: true

module TestProf
  module EventProf
    module Printers
      module Base
        include TestProf::Logging

        private

        def describe_group(id)
          id.is_a?(Hash) ? id[:name] : id.top_level_description
        end

        def describe_example(id)
          id.is_a?(Hash) ? id[:name] : id.description
        end

        def locate(id)
          id.is_a?(Hash) ? id[:location] : id.metadata[:location]
        end

        def time_percentage(time, total_time)
          (time / total_time * 100).round(2)
        end
      end
    end
  end
end
