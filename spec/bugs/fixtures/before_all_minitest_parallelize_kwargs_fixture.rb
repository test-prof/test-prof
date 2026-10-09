# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require "minitest/autorun"
require "active_support/core_ext/module/attribute_accessors"
require "test_prof/recipes/minitest/before_all"

class ParallelizeKwargsTest < Minitest::Test
  class << self
    attr_reader :parallelize_args

    # Not the real ActiveSupport::TestCase.parallelize: its signature changes per Rails version,
    # and only "forward everything to super" is under test here
    def parallelize(**kwargs)
      @parallelize_args = kwargs
      :executor
    end
  end

  # Included after the fake is defined: the patch is only installed when respond_to?(:parallelize) is true
  include TestProf::BeforeAll::Minitest

  # some_future_option: is unknown to Rails on purpose: the patch must not enumerate keywords
  parallelize(workers: 2, threshold: 100, some_future_option: true)

  def test_forwards_every_keyword_argument
    assert_equal({workers: 2, with: :processes, threshold: 100, some_future_option: true}, self.class.parallelize_args)
    assert_equal true, self.class.parallelized
  end
end
