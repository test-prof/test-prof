# frozen_string_literal: true

module TestProf
  # Add ability to run only a specified number of example groups (randomly selected)
  module MinitestSample
    # Do not add these classes to resulted sample
    CORE_RUNNABLES = [
      Minitest::Test,
      Minitest::Unit::TestCase,
      Minitest::Spec
    ].freeze

    def run(*)
      unless ENV['SAMPLE'].nil?
        sample_size = ENV['SAMPLE'].to_i
        # Make sure that sample contains only _real_ suites
        runnables = Minitest::Runnable.runnables
                                      .sample(sample_size + CORE_RUNNABLES.size)
                                      .reject { |suite| CORE_RUNNABLES.include?(suite) }
                                      .take(sample_size)
        Minitest::Runnable.reset
        runnables.each { |r| Minitest::Runnable.runnables << r }
      end
      super
    end
  end
end

Minitest.singleton_class.prepend(TestProf::MinitestSample)
