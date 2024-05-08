# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)
require "minitest/autorun"
require "test_prof/recipes/minitest/sample"

class SomethingTest < Minitest::Test
  def test_pass
    assert true
  end

  def test_pass2
    assert true
  end
end

class CustomTestCase < Minitest::Test
end

class AnotherSomethingTest < CustomTestCase
  def test_pass
    assert true
  end

  def test_pass2
    assert true
  end
end

class NothingTest < Minitest::Test
  def test_pass
    refute false
  end

  def test_pass2
    assert true
  end
end
