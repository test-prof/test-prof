# frozen_string_literal: true

module TestProf
  module TagProf # :nodoc:
    # Object holding all the stats for tags
    class Result
      attr_reader :tag, :data

      def initialize(tag)
        @tag = tag
        @data = Hash.new { |h, k| h[k] = { value: k, count: 0, time: 0.0 } }
      end

      def track(tag, time:)
        data[tag][:count] += 1
        data[tag][:time] += time
      end

      def to_json
        {
          tag: tag,
          data: data.values
        }.to_json
      end
    end
  end
end
