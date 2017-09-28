# frozen_string_literal: true

require "test_prof/ext/float_duration"
require "test_prof/ext/string_truncate"
require "test_prof/ext/string_strip_heredoc"

class MinitestFormatter
  using TestProf::FloatDuration
  using TestProf::StringTruncate
  using TestProf::StringStripHeredoc

  def initialize(profiler)
    @profiler = profiler
    @results = []
  end

  def prepare_results
    total_results
    by_groups
    by_examples
    @results.join
  end

  private

  def total_results
    @results <<
      <<-MSG.strip_heredoc
        EventProf results for #{@profiler.event}

        Total time: #{@profiler.total_time.duration}
        Total events: #{@profiler.total_count}

        Top #{@profiler.top_count} slowest suites (by #{@profiler.rank_by}):

      MSG
  end

  def by_groups
    @profiler.results[:groups].each do |group|
      description = group[:id][:name]
      location = group[:id][:location]

      @results <<
        <<-GROUP.strip_heredoc
          #{description.truncate} (#{location}) – #{group[:time].duration} (#{group[:count]} / #{group[:examples]})
        GROUP
    end
  end

  def by_examples
    if @profiler.results[:examples]
      @results << "\nTop #{@profiler.top_count} slowest tests (by #{@profiler.rank_by}):\n\n"

      @profiler.results[:examples].each do |example|
        description = example[:id][:name]
        location = example[:id][:location]

        @results <<
          <<-GROUP.strip_heredoc
            #{description.truncate} (#{location}) – #{example[:time].duration} (#{example[:count]})
          GROUP
      end
    end
  end
end

