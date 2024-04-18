# frozen_string_literal: true

number_regex = /\d+\.?\d{0,2}/
memory_human_regex = /#{number_regex}[KMGTPEZ]?B/
percent_regex = /#{number_regex}%/

describe "MemoryProf RSpec" do
  specify "with default options", :aggregate_failures do
    output = run_rspec("memory_prof", env: {"TEST_MEM_PROF" => "test", "TEST_MEM_PROF_COUNT" => "3"})

    expect(output).to include("MemoryProf results")
    expect(output).to match(/Final RSS: #{memory_human_regex}/)

    expect(output).to include("Top 3 groups (by RSS):")
    expect(output).to include("Top 3 examples (by RSS):")
  end

  specify "in RSS mode", :aggregate_failures do
    output = run_rspec("memory_prof", env: {"TEST_MEM_PROF" => "rss", "TEST_MEM_PROF_COUNT" => "3"})

    expect(output).to include("MemoryProf results")
    expect(output).to match(/Final RSS: #{memory_human_regex}/)

    expect(output).to include("Top 3 groups (by RSS):")
    expect(output).to include("Top 3 examples (by RSS):")
  end

  if RUBY_ENGINE != "jruby"
    specify "in allocations mode", :aggregate_failures do
      output = run_rspec("memory_prof", env: {"TEST_MEM_PROF" => "alloc", "TEST_MEM_PROF_COUNT" => "3"})

      expect(output).to include("MemoryProf results")
      expect(output).to match(/Total allocations: #{number_regex}/)

      expect(output).to include("Top 3 groups (by allocations):")
      expect(output).to include("Top 3 examples (by allocations):")

      expect(output).to match(/with 10_000 allocations \(\.\/memory_prof_fixture.rb:\d+\) – \+#{number_regex} \(#{percent_regex}\)/)
      expect(output).to match(/with 1000 allocations \(\.\/memory_prof_fixture.rb:\d+\) – \+#{number_regex} \(#{percent_regex}\)/)
      expect(output).to match(/with 500 allocations \(\.\/memory_prof_fixture.rb:\d+\) – \+#{number_regex} \(#{percent_regex}\)/)

      expect(output).to match(/allocates 10_000 objects \(\.\/memory_prof_fixture.rb:\d+\) – \+#{number_regex} \(#{percent_regex}\)/)
      expect(output).to match(/allocates 1000 objects \(\.\/memory_prof_fixture.rb:\d+\) – \+#{number_regex} \(#{percent_regex}\)/)
      expect(output).to match(/allocates 500 objects \(\.\/memory_prof_fixture.rb:\d+\) – \+#{number_regex} \(#{percent_regex}\)/)
    end
  end

  specify "with top_count", :aggregate_failures do
    output = run_rspec("memory_prof", env: {"TEST_MEM_PROF" => "rss", "TEST_MEM_PROF_COUNT" => "4"})

    expect(output).to include("MemoryProf results")
    expect(output).to match(/Final RSS: #{memory_human_regex}/)

    expect(output).to include("Top 4 groups (by RSS):")
    expect(output).to include("Top 4 examples (by RSS):")
  end
end
