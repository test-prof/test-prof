# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require "minitest/autorun"
require "test_prof"

TestProf.configure do |config|
  config.output_dir = "../../../../tmp/test_prof"
end

class SomethingTest < Minitest::Test
  def test_pass
    assert true
  end

  def test_pass2
    assert true
  end
end
