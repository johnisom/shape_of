# Copyright 2021 John Isom.
# Licensed under the open source MIT license.

require 'minitest/autorun'
require 'minitest/reporters'
MiniTest::Reporters.use!
require 'shape_of'

class ShapeOfTest < Minitest::Test
  def test_shape_of_is_defined
    assert_equal "constant", defined? ShapeOf
    assert_equal Module, ShapeOf.class
  end

  def test_assertions_is_defined
    assert_equal "constant", defined? ShapeOf::Assertions
    assert_equal Module, ShapeOf::Assertions.class
  end

  def test_shape_is_defined
    assert_equal "constant", defined? ShapeOf::Shape
    assert_equal Class, ShapeOf::Shape.class
  end

  def test_array_is_defined
    assert_equal "constant", defined? ShapeOf::Array
    assert_equal Class, ShapeOf::Array.class
  end

  def test_hash_is_defined
    assert_equal "constant", defined? ShapeOf::Hash
    assert_equal Class, ShapeOf::Hash.class
  end

  def test_union_is_defined
    assert_equal "constant", defined? ShapeOf::Union
    assert_equal Class, ShapeOf::Union.class
  end

  def test_optional_is_defined
    assert_equal "constant", defined? ShapeOf::Optional
    assert_equal Class, ShapeOf::Optional.class
  end

  def test_any_is_defined
    assert_equal "constant", defined? ShapeOf::Any
    assert_equal Class, ShapeOf::Any.class
  end

  def test_nothing_is_defined
    assert_equal "constant", defined? ShapeOf::Nothing
    assert_equal Class, ShapeOf::Nothing.class
  end

  def test_numeric_is_defined
    assert_equal "constant", defined? ShapeOf::Numeric
    assert_equal Class, ShapeOf::Numeric.class
  end

  def test_boolean_is_defined
    assert_equal "constant", defined? ShapeOf::Boolean
    assert_equal Class, ShapeOf::Boolean.class
  end

  def test_hash_was_monkey_patched
    assert_equal "method", defined? Hash.new.to_shape_of
  end

  def test_array_was_monkey_patched
    assert_equal "method", defined? Array.new.to_shape_of
  end
end