# Copyright 2021 John Isom.
# Licensed under the open source MIT license.

require 'minitest/autorun'
require 'minitest/reporters'
MiniTest::Reporters.use!
require 'shape_of'

class ShapeOfTest < Minitest::Test
  def assert_shape_of_many shape, objs
    objs.each do |obj|
      assert_operator shape, :shape_of?, obj
    end
  end

  def refute_shape_of_many shape, objs
    objs.each do |obj|
      refute_operator shape, :shape_of?, obj
    end
  end

  # Generic definition tests

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
    assert_operator Hash.new, :respond_to?, :to_shape_of
  end

  def test_array_was_monkey_patched
    assert_operator Array.new, :respond_to?, :to_shape_of
  end

  # Shape

  def test_shape_shape_of_raises_error
    assert_operator ShapeOf::Shape, :respond_to?, :shape_of?
    assert_raises(NotImplementedError) { ShapeOf::Shape.shape_of?({}) }
  end

  def test_shape_new_raises_error
    assert_raises(NotImplementedError) { ShapeOf::Shape.new }
  end

  def test_shape_is_required
    assert_operator ShapeOf::Shape, :respond_to?, :required?
    assert ShapeOf::Shape.required?
  end

  # Array

  # Hash

  # Union

  def test_union
    assert_operator ShapeOf::Union, :respond_to?, :required?
    assert_predicate ShapeOf::Union, :required?

    assert_shape_of_many ShapeOf::Union[Integer, String], [1, 4, 21, 65, "hello", "world", '', 'bar'.freeze, -345, 0, +"d"]
    refute_shape_of_many ShapeOf::Union[Integer, String], [nil, true, false, { foo: 2 }, [], /regex/, Set.new, 1.upto(10)]
  end

  # Optional

  def test_optional
    assert_operator ShapeOf::Optional, :respond_to?, :required?
    assert_operator ShapeOf::Optional[String], :respond_to?, :required?
    refute_predicate ShapeOf::Optional, :required?
    refute_predicate ShapeOf::Optional[String], :required?
    assert_raises(NotImplementedError) { ShapeOf::Optional.shape_of?({}) }
    assert_raises(TypeError)  { ShapeOf::Optional[NilClass] }

    assert_shape_of_many ShapeOf::Optional[String], [nil, 'foo', 'bar', '1', '', 'nil', nil, 'true', '[]']
    refute_shape_of_many ShapeOf::Optional[String], [1, [], {}, ['hello']]
  end

  def test_optional_with_hash
    shape = ShapeOf::Hash[
      foo: ShapeOf::Optional[Integer]
    ]

    assert_shape_of_many shape, [{ foo: 1 }, { foo: nil }, {}]
    refute_shape_of_many shape, [{ foo: 1.2 }, { foo: 'nil' }]
  end

  # Any

  def test_any
    assert_operator ShapeOf::Any, :respond_to?, :required?
    assert_predicate ShapeOf::Any, :required?

    assert_shape_of_many ShapeOf::Any, [1, 1.0, 1/1r, 1+1i, '', 'hello', [], [1], {}, { foo: 'bar' }, /regex/, Set.new, 1.upto(10), true, false, nil]
  end

  def test_any_with_hash
    shape = ShapeOf::Hash[
      foo: ShapeOf::Any
    ]

    refute_operator shape, :shape_of?, {}
    assert_shape_of_many shape, [{ foo: nil }, { foo: :bar }, { foo: "world" }, { foo: { bar: { bam: { baz: "" } } } }]
  end

  # Nothing

  def test_nothing
    assert_operator ShapeOf::Nothing, :respond_to?, :required?
    refute_predicate ShapeOf::Nothing, :required?

    refute_shape_of_many ShapeOf::Nothing, [1, 1.0, 1/1r, 1+1i, '', 'hello', [], [1], {}, { foo: 'bar' }, /regex/, Set.new, 1.upto(10), true, false, nil]
  end

  def test_nothing_with_hash
    shape = ShapeOf::Hash[
      foo: ShapeOf::Nothing
    ]

    assert_operator shape, :shape_of?, {}
    refute_shape_of_many shape, [{ foo: nil }, { foo: :bar }, { hello: "world" }, [{}]]
  end

  # Numeric

  def test_numeric
    assert_shape_of_many ShapeOf::Numeric, [3234, -12, 1.1, -0.3223, 3r, 2/3r, 3i, 2+3i]
    refute_shape_of_many ShapeOf::Numeric, ['', 'foo', [], [1, 1.2], [''], {}, { foo: 1 }]
  end

  # Boolean

  def test_boolean
    assert_shape_of_many ShapeOf::Boolean, [true, false]
    refute_shape_of_many ShapeOf::Boolean, [TrueClass, FalseClass, ShapeOf::Boolean, nil, 1, 0, 'true', 'false', {}, [], { foo: true }, [true]]
  end

  # ::Hash

  def test_hash_to_shape_of
    hash = {foo: Integer}

    shape = hash.to_shape_of

    assert_includes shape.ancestors, ShapeOf::Hash
    assert_operator shape, :shape_of?, { foo: 1 }
    refute_shape_of_many shape, [{ bar: 1 }, { foo: Integer }, { foo: 1.2 }, { foo: 'bar' }, { foo: nil }]
  end

  # ::Array

  def test_array_to_shape_of
    array = [Integer]

    shape = array.to_shape_of

    assert_includes shape.ancestors, ShapeOf::Array
    assert_shape_of_many shape, [[], [1, 2, 3]]
    refute_operator shape, :shape_of?, [1, 'foo', nil]
  end
end
