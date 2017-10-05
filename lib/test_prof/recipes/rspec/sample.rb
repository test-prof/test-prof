# frozen_string_literal: true

module TestProf
  # Add ability to run only a specified number of example groups (randomly selected)
  module RSpecSample
    def ordered_example_groups
      @example_groups = @example_groups.sample(ENV['SAMPLE'].to_i) unless ENV['SAMPLE'].nil?
      super
    end
  end
end

RSpec::Core::World.prepend(TestProf::RSpecSample)
