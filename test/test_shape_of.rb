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

  def test_pattern_is_defined
    assert_equal "constant", defined? ShapeOf::Pattern
    assert_equal Class, ShapeOf::Pattern.class
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

  def test_array
    assert_operator ShapeOf::Array, :respond_to?, :required?
    assert_predicate ShapeOf::Array, :required?

    assert_raises(ArgumentError) { ShapeOf::Array[1, 2, 3] } # use ShapeOf::Array[ShapeOf::Union[1, 2, 3]] if you want an array of only those 3 integers

    assert_shape_of_many ShapeOf::Array, [[], [1], [[[[[[[[[]]]]]]]]], [1, [1, 2], '', { foo: [1, { bar: :baz }] }, 1.2], [nil, nil], [*1..10]]
    refute_shape_of_many ShapeOf::Array, [{}, '', 1, 1.2, {foo: [[]]}, /regex/, Set.new([]), nil, true, false, 1.upto(20)]

    assert_shape_of_many ShapeOf::Array[ShapeOf::Boolean], [[], [true], [false], [true, true], [true, false, true, false, false, false, true]]
  end

  def test_compound_array
    shape = ShapeOf::Array[
      ShapeOf::Array[
        ShapeOf::Array[
          ShapeOf::Array[
            ShapeOf::Array[
            Integer
            ]
          ]
        ]
      ]
    ]

    arr = [1, 2, 3]
    4.times do
      arr = [[], arr, [], arr, []]
    end

    assert_shape_of_many shape, [[], [[]], [[], []], [[], [[[]]], [[]]], [[[[[1, 2, 3], [1, 2, 3]], [[1, 2, 3], [1, 2, 3]]]]], arr]
    refute_shape_of_many shape, [true, false, nil, [1], [[1]], [[[1]]], [[[[1]]]], [[[[[1, 'nil']]]]], [[[[[], ['']]]]]]
  end

  def test_array_with_hash
    shape = ShapeOf::Array[
      ShapeOf::Hash[
        foo: ShapeOf::Array[
          ShapeOf::Hash[
            bar: Array
          ]
        ]
      ]
    ]

    assert_shape_of_many shape, [[], [{ foo: [] }], [{ foo: [{ bar: [{ foo: [{ bar: [] }] }] }] }]]
    refute_shape_of_many shape, [{}, [[]], [{}], [{ foo: [12233] }]]
  end

  def test_array_literal_syntax_with_hash
    shape = ShapeOf::Hash[
      arr: [String]
    ]

    assert_shape_of_many shape, [{ arr: [] }, { arr: [""] }, { arr: ["foo", "bar"] }]
    refute_shape_of_many shape, [nil, {}, { arr: nil }, { arr: [2] }]
  end

  # Hash

  def test_hash
    assert_operator ShapeOf::Hash, :respond_to?, :required?
    assert_predicate ShapeOf::Hash, :required?

    assert_shape_of_many ShapeOf::Hash, [{}, {foo: :bar}, {"baz" => ["bam"]}, { [1, 2, 3] => [4, 5, 6] }]
    assert_shape_of_many ShapeOf::Hash[foo: String], [{ foo: '' }, { foo: 'hello' }, { "foo" => "bar" }]
    refute_shape_of_many ShapeOf::Hash[foo: String], [{}, { foo: nil }, { foo: :bar }, { 'pi' => 3.1415926 }, { foo: 'bar', baz: nil }] 
  end

  def test_compound_hash
    shape = ShapeOf::Hash[
      foo: ShapeOf::Hash[
        bar: ShapeOf::Hash[
          baz: ShapeOf::Hash[
            bam: ShapeOf::Hash[
              quz: String
            ]
          ]
        ]
      ]
    ]

    assert_shape_of_many shape, [{ foo: { bar: { baz: { bam: { quz: '' } } } } }, { "foo" => { bar: { "baz" => { bam: { "quz" => 'hello world' } } } } }]
    refute_shape_of_many shape, [{}, nil, { foo: {} }, { "foo" => {}}, { foo: { bar: { baz: { quz: { bam: 'foo' } } } } }]
  end

  def test_hash_with_array
    shape = ShapeOf::Hash[
      foo: ShapeOf::Array[
        ShapeOf::Hash[
          bar: String
        ]
      ],
      bam: String
    ]

    assert_shape_of_many shape, [{ foo: [], bam: '' }, { foo: [], bam: 'not empty' }, { foo: [{ bar: '' }], bam: 'test data' }, { foo: [{ bar: '' }, { bar: '123' }, { bar: 'asdf' }, { "bar" => '' }], bam: 'test data' }]
    refute_shape_of_many shape, [{ foo: [] }, { bam: '' }, { foo: [{}], bam: '' }, { foo: [nil], bam: 'whoz' }, { foo: [{ bar: nil }], bam: '' }, { foo: [{ bar: '' }, { bar: '' }, nil], bam: 'foo' }]
  end

  # Union

  def test_union
    assert_operator ShapeOf::Union, :respond_to?, :required?
    assert_predicate ShapeOf::Union, :required?

    assert_shape_of_many ShapeOf::Union[Integer, String], [1, 4, 21, 65, "hello", "world", '', 'bar'.freeze, -345, 0, +"d"]
    refute_shape_of_many ShapeOf::Union[Integer, String], [nil, true, false, { foo: 2 }, [], /regex/, Set.new, 1.upto(10)]
  end

  def test_union_with_hash
    shape = ShapeOf::Hash[
      foo: ShapeOf::Union[String, ShapeOf::Numeric]
    ]

    assert_shape_of_many shape, [{ foo: 1 }, { foo: 1.2 }, { foo: 'bar' }, { foo: '' }, { foo: 1+2i }]
    refute_shape_of_many shape, [{}, { foo: nil }, { foo: :foo }]
  end

  def test_union_with_array
    shape = ShapeOf::Array[ShapeOf::Union[1, 2, 3, Float, ShapeOf::Array[String]]]

    assert_shape_of_many shape, [[], [1], [1, 1, 1, 1, 1], [1, 2, 3, 2, 1], [1, 1.1, 2, 2.2, 2.1, 3, 1.4829382, 1.4892393], [1, 1.123, -1.2, -1.4, ['foo', 'bar']]]
    refute_shape_of_many shape, [[1/2r], [1+1i], ['hello'], ['world'], [[1, 2, 3]], [1, 2, 3, 2, 1.1, 1.2, 1.3, 'hello'], [nil], [[[]]], [{}]]
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

  # Pattern

  def test_pattern
    assert_operator ShapeOf::Pattern, :respond_to?, :required?
    assert_predicate ShapeOf::Pattern, :required?
    assert_raises(NotImplementedError) { ShapeOf::Pattern.shape_of?('foo') }
    assert_raises(TypeError) { ShapeOf::Pattern['foobar'] }
    assert_raises(TypeError) { ShapeOf::Pattern[/foobar/].shape_of?(/foobar/) }
    assert_raises(TypeError) { ShapeOf::Pattern[/foobar/].shape_of?(['hello']) }

    assert_shape_of_many ShapeOf::Pattern[/foobar/], ['foobar', "\n\nfoobar\n\n", /^foobar$/imx.to_s, "qwertyuiopasdfghjklzxcvbnmfoobarqwertyuioopasdfghjklzxcvbnm"]
    refute_shape_of_many ShapeOf::Pattern[/foobar/], ['fobar', '']
    assert_shape_of_many ShapeOf::Pattern[/^whoa/i], ['whoa there', 'WHOA there!', "whoa hello\nwhoa there\nwhoa whoa!"]
    refute_shape_of_many ShapeOf::Pattern[/^whoa/i], ['hey, whoa there', " WHOA there!"]
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

  # All together now

  def test_everything
    shape1 = ShapeOf::Array[ShapeOf::Union[ShapeOf::Hash[foo: ShapeOf::Optional[String]], 1, 1.43, ShapeOf::Boolean]]
    shape2 = ShapeOf::Hash[foo: shape1, bar: ShapeOf::Hash[baz: ShapeOf::Union[ShapeOf::Numeric, shape1]]]
    shape3 = ShapeOf::Union[Integer, String, NilClass, ShapeOf::Boolean, ShapeOf::Numeric, ShapeOf::Nothing, ShapeOf::Hash[bar: ShapeOf::Any]]
    shape4 = ShapeOf::Hash[shape1: shape1, shape2: shape2, shape3: shape3]

    shape_1_assertions = [
      [],
      [1, 1, 1, 1.43, true, false, false, true],
      [1, 1, 1.43, {}, { foo: nil }, { foo: 'bar' }]
    ]
    assert_shape_of_many shape1, shape_1_assertions

    shape_1_refutations = [
      [[]],
      [nil],
      [''],
      [{ foo: 1 }, 1, 1, 1, 1.43]
    ]
    refute_shape_of_many shape1, shape_1_refutations

    shape_2_assertions = [
      {
        foo: [],
        bar: {
          baz: []
        }
      },
      {
        foo: [],
        bar: {
          baz: Math::E**(Math::PI * 1i)
        }
      },
      {
        foo: [1, 1, 1.43, {}, { foo: nil }, { foo: 'bar' }],
        bar: {
          baz: [1, 1, 1.43, {}, { foo: nil }, { foo: 'bar' }]
        }
      },
      {
        foo: [1, false, false, false, true, false, false, true, 1, 1.43, {}, { foo: nil }, { foo: 'bar' }],
        bar: {
          baz: [1, 1, 1.43, {}, { foo: nil }, { foo: 'bar' }]
        }
      },
    ]
    assert_shape_of_many shape2, shape_2_assertions

    shape_2_refutations = [
      {},
      { foo: nil },
      { bar: nil },
      { foo: nil, bar: nil },
      { foo: [1], bar: {} },
      { foo: [1], bar: { baz: ''} },
      { foo: [1], bar: { baz: '1'} },
      { foo: [1], bar: { baz: [[]] } },
      { foo: [1], bar: { baz: [''] } },
      { foo: [1], bar: { baz: [{ foo: 1 }, 1, true, false] } }
    ]
    refute_shape_of_many shape2, shape_2_refutations

    shape_3_assertions = [
      1,
      'foobar',
      '',
      nil,
      true,
      false,
      1.322432,
      12+1/2ri,
      { bar: nil },
      { bar: ['{' ,{ baz: Object.new, }, '}'] },
      { bar: [shape1, shape2, shape3, shape4, self, (-97866812345/128934r+9871234/1982734ri)] },
      { bar: nil }
    ]
    assert_shape_of_many shape3, shape_3_assertions

    shape_3_refutations = [
      {},
      /regex/,
      -> (abc) { puts abc },
      []
    ]
    refute_shape_of_many shape3, shape_3_refutations

    shape_4_assertions = []
    shape_1_assertions.each do |s1|
      shape_2_assertions.each do |s2|
        shape_3_assertions.each do |s3|
          shape_4_assertions << { shape1: s1, shape2: s2, shape3: s3 }
        end
      end
    end
    assert_shape_of_many shape4, shape_4_assertions

    shape_4_refutations = []
    shape_1_refutations.each do |s1|
      shape_2_refutations.each do |s2|
        shape_3_refutations.each do |s3|
          shape_4_refutations << { shape1: s1, shape2: s2, shape3: s3 }
        end
      end
    end
    shape_1_assertions.each do |s1|
      shape_2_assertions.each do |s2|
        shape_3_assertions.each do |s3|
          shapes = { shape1: s1, shape2: s2, shape3: s3 }.to_a
          0.upto(2).each do |length|
            shape_4_refutations << shapes.combination(length).map(&:to_h)
          end
        end
      end
    end
    refute_shape_of_many shape4, shape_4_refutations
  end
end
