# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)

module RSpec
  def self.foo; end
end

require "minitest/autorun"
require "test_prof"

class SomethingTest < Minitest::Test
  def test_pass
    assert true
  end
end
