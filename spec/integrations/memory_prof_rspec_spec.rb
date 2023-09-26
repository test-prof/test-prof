# frozen_string_literal: true

number_regex = /\d+\.?\d{0,2}/
memory_human_regex = /#{number_regex}[KMGTPEZ]?B/
percent_regex = /#{number_regex}%/

describe "MemoryProf RSpec" do
  specify "with default options", :aggregate_failures do
    output = run_rspec("memory_prof", env: {"TEST_MEM_PROF" => "test"})

    expect(output).to include("MemoryProf results")
    expect(output).to match(/Final RSS: #{memory_human_regex}/)

    expect(output).to include("Top 5 groups (by RSS):")
    expect(output).to include("Top 5 examples (by RSS):")

    expect(output).to match(/with 10_000 allocations \(\.\/memory_prof_fixture.rb:39\) – \+#{memory_human_regex} \(#{percent_regex}\)/)
    expect(output).to match(/with 1000 allocations \(\.\/memory_prof_fixture.rb:30\) – \+#{memory_human_regex} \(#{percent_regex}\)/)
    expect(output).to match(/with 500 allocations \(\.\/memory_prof_fixture.rb:21\) – \+#{memory_human_regex} \(#{percent_regex}\)/)
    expect(output).to match(/Groups Allocations \(\.\/memory_prof_fixture.rb:20\) – \+#{memory_human_regex} \(#{percent_regex}\)/)
    expect(output).to match(/Examples allocations \(\.\/memory_prof_fixture.rb:6\) – \+#{memory_human_regex} \(#{percent_regex}\)/)

    expect(output).to match(/allocates 10_000 objects \(\.\/memory_prof_fixture.rb:15\) – \+#{memory_human_regex} \(#{percent_regex}\)/)
    expect(output).to match(/allocates 1000 objects \(\.\/memory_prof_fixture.rb:11\) – \+#{memory_human_regex} \(#{percent_regex}\)/)
    expect(output).to match(/allocates 500 objects \(\.\/memory_prof_fixture.rb:7\) – \+#{memory_human_regex} \(#{percent_regex}\)/)
  end

  specify "in RSS mode", :aggregate_failures do
    output = run_rspec("memory_prof", env: {"TEST_MEM_PROF" => "rss"})

    expect(output).to include("MemoryProf results")
    expect(output).to match(/Final RSS: #{memory_human_regex}/)

    expect(output).to include("Top 5 groups (by RSS):")
    expect(output).to include("Top 5 examples (by RSS):")

    expect(output).to match(/with 10_000 allocations \(\.\/memory_prof_fixture.rb:39\) – \+#{memory_human_regex} \(#{percent_regex}\)/)
    expect(output).to match(/with 1000 allocations \(\.\/memory_prof_fixture.rb:30\) – \+#{memory_human_regex} \(#{percent_regex}\)/)
    expect(output).to match(/with 500 allocations \(\.\/memory_prof_fixture.rb:21\) – \+#{memory_human_regex} \(#{percent_regex}\)/)
    expect(output).to match(/Groups Allocations \(\.\/memory_prof_fixture.rb:20\) – \+#{memory_human_regex} \(#{percent_regex}\)/)
    expect(output).to match(/Examples allocations \(\.\/memory_prof_fixture.rb:6\) – \+#{memory_human_regex} \(#{percent_regex}\)/)

    expect(output).to match(/allocates 10_000 objects \(\.\/memory_prof_fixture.rb:15\) – \+#{memory_human_regex} \(#{percent_regex}\)/)
    expect(output).to match(/allocates 1000 objects \(\.\/memory_prof_fixture.rb:11\) – \+#{memory_human_regex} \(#{percent_regex}\)/)
    expect(output).to match(/allocates 500 objects \(\.\/memory_prof_fixture.rb:7\) – \+#{memory_human_regex} \(#{percent_regex}\)/)
  end

  if RUBY_ENGINE != "jruby"
    specify "in allocations mode", :aggregate_failures do
      output = run_rspec("memory_prof", env: {"TEST_MEM_PROF" => "alloc"})

      expect(output).to include("MemoryProf results")
      expect(output).to match(/Total allocations: #{number_regex}/)

      expect(output).to include("Top 5 groups (by allocations):")
      expect(output).to include("Top 5 examples (by allocations):")

      expect(output).to match(/with 10_000 allocations \(\.\/memory_prof_fixture.rb:39\) – \+#{number_regex} \(#{percent_regex}\)/)
      expect(output).to match(/with 1000 allocations \(\.\/memory_prof_fixture.rb:30\) – \+#{number_regex} \(#{percent_regex}\)/)
      expect(output).to match(/with 500 allocations \(\.\/memory_prof_fixture.rb:21\) – \+#{number_regex} \(#{percent_regex}\)/)
      expect(output).to match(/Groups Allocations \(\.\/memory_prof_fixture.rb:20\) – \+#{number_regex} \(#{percent_regex}\)/)
      expect(output).to match(/Examples allocations \(\.\/memory_prof_fixture.rb:6\) – \+#{number_regex} \(#{percent_regex}\)/)

      expect(output).to match(/allocates 10_000 objects \(\.\/memory_prof_fixture.rb:15\) – \+#{number_regex} \(#{percent_regex}\)/)
      expect(output).to match(/allocates 1000 objects \(\.\/memory_prof_fixture.rb:11\) – \+#{number_regex} \(#{percent_regex}\)/)
      expect(output).to match(/allocates 500 objects \(\.\/memory_prof_fixture.rb:7\) – \+#{number_regex} \(#{percent_regex}\)/)
    end
  end

  specify "with top_count", :aggregate_failures do
    output = run_rspec("memory_prof", env: {"TEST_MEM_PROF" => "rss", "TEST_MEM_PROF_COUNT" => "3"})

    expect(output).to include("MemoryProf results")
    expect(output).to match(/Final RSS: #{memory_human_regex}/)

    expect(output).to include("Top 3 groups (by RSS):")
    expect(output).to include("Top 3 examples (by RSS):")
  end
end
