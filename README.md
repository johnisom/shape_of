<!--
  Copyright 2021 John Isom.
  Licensed under the MIT open source license.
-->

# ShapeOf

A RubyGem that provides a way to verify "shapes" of objects.

This is licenced under the MIT license, Copyright 2021 John Isom.

## Example Usage

Taken from `lib/shape_of.rb`.

For example, given this hash, where `friendly_name`, `external_id`, `external_avatar_url`, and `data` are optional:
```ruby
hash = {
  id: 123,
  name: "John Doe",
  friendly_name: "Johnny",
  external_id: "",
  external_avatar_url: "https://example.com/avatar.jpg",
  data: {
    status: "VIP"
  },
  identities: [
    {
      id: 1,
      type: "email",
      identifier: "john37@example.com"
    }
  ],
  created_at: "2020-12-28T15:55:35.121Z",
  updated_at: "2020-12-28T15:55:35.121Z"
}
```

the proper shape would be this:
```ruby
shape = ShapeOf::Hash[
  id: Integer,
  name: String,
  friendly_name: ShapeOf::Optional[String],
  external_id: ShapeOf::Optional[String],
  external_avatar_url: ShapeOf::Optional[String],
  data: ShapeOf::Optional[Hash],
  identities: ShapeOf::Array[
    ShapeOf::Hash[
      id: Integer,
      type: String,
      identifier: String
    ]
  ],
  created_at: String,
  updated_at: String
]

shape.shape_of? hash # => true
```

As another example, given this shape:
```ruby
hash_shape = ShapeOf::Hash[
  value: ShapeOf::Optional[
    ShapeOf::Union[
      ShapeOf::Array[
        ShapeOf::Hash[
          inner_value: ShapeOf::Any
        ]
      ],
      ShapeOf::Hash[
        inner_value: ShapeOf::Any
      ]
    ]
  ]
]
```

These shapes pass:
```ruby
hash_shape.shape_of?({ value: { inner_value: 3 } }) # => true
hash_shape.shape_of?({ value: [{ inner_value: 3 }] }) # => true
hash_shape.shape_of?({ value: [{ inner_value: 3 }, { inner_value: "foo" }, { inner_value: [1, 2, 3] }] }) # => true
```

And these fail:
```ruby
hash_shape.shape_of?({ foo: { inner_value: 'bar' } }) # => false
hash_shape.shape_of?({ value: 23 }) # => false
hash_shape.shape_of?({ value: [23] }) # => false
hash_shape.shape_of?({ value: [{}] }) # => false
```

### Other Usage

Alternatively, ShapeOf can be used with ruby objects rather than `ShapeOf::Hash` and `ShapeOf::Array`:

```ruby
ShapeOf::Hash[
  id: Integer,
  identities: [
    {
      id: Integer,
      data: {
        type: String
      }
    }
  ]
]
# that is equivalent to:
ShapeOf::Hash[
  id: Integer,
  identities: ShapeOf::Array[
    ShapeOf::Hash[
      id: Integer,
      data: ShapeOf::Hash[
        type: String
      ]
    ]
  ]
]
# which in turn is equivalent to
{
  id: Integer,
  identities: [
    {
      id: Integer,
      data: {
        type: String
      }
    }
  ]
}.to_shape_of

```

ShapeOf can also be used to test actual values instead of classes. For example:
```ruby
shape = ShapeOf::Union["hello", "world", "foobar", 1, 1.423]

shape.shape_of? "hello" # => true
shape.shape_of? "world" # => true
shape.shape_of? "foobar" # => true
shape.shape_of? 1 # => true
shape.shape_of? 1.423 # => true
shape.shape_of? "other string" # => false
shape.shape_of? nil # => false
shape.shape_of? 1.42300001 # => false
shape.shape_of? Object.new # => false
``` 

So, if you wanted to test that the field `foo` in a hash is optional but if it exists
it either is a String or the integers 1-5, you could do so like this: 
```ruby
shape = ShapeOf::Hash[bar: String, foo: ShapeOf::Optional[ShapeOf::Union[String, *1..5]]]

shape.shape_of?({ bar: 'foobar' }) # => true
shape.shape_of?({}) # => false
shape.shape_of?({ bar: '', foo: 1 }) # => true
shape.shape_of?({ bar: '', foo: 2 }) # => true
shape.shape_of?({ bar: '', foo: 3 }) # => true
shape.shape_of?({ bar: '', foo: 4 }) # => true
shape.shape_of?({ bar: '', foo: 5 }) # => true
shape.shape_of?({ bar: '', foo: 6 }) # => false
shape.shape_of?({ bar: '', foo: "6" }) # => true
shape.shape_of?({ bar: '', foo: nil }) # => true
 ```

## Provided Shapes

### `ShapeOf::Hash`

Pulled from comments from the source code:

> `Hash[key: shape, ...]` denotes it is a hash of shapes with a very specific structure.
> `Hash` (without square brackets) is just a hash with any shape.
> This, along with `Array`, are the core components of this module.
> Note that the keys are converted to strings for comparison for both the shape and object provided.

Example:
```ruby
# note that keyword args can be provided directly or wrapped in curly braces
shape = ShapeOf::Hash[foo: String, bar: ShapeOf::Hash[{ baz: Integer }]]

shape.shape_of?({ foo: "", bar: { baz: 1 } }) # => true
shape.shape_of?({ foo: "foo", bar: { baz: -2 } }) # => true
shape.shape_of?({}) # => false
shape.shape_of?({ bar: { baz: 2 } }) # => false
shape.shape_of?({ foo: "foo", bar: {} }) # => false
shape.shape_of?({ foo: "foo", bar: { baz: -2, blamo: nil } }) # => false
shape.shape_of?({ foo: "foo", bar: { baz: -2 }, blamo: nil }) # => false
```

### `ShapeOf::Array`

Pulled from comments from the source code:

> `Array[shape]` denotes that it is an array of shapes.
> It checks every element in the array and verifies that the element is in the correct shape.
> This, along with `Hash`, are the core components of this module.
> Note that a `ShapeOf::Array[Integer].shape_of?([])` will pass because it is vacuously true for an empty array.

Example:
```ruby
shape = ShapeOf::Array[String]

shape.shape_of?([]) # => true
shape.shape_of?(["foobar"]) # => true
shape.shape_of?(["a", "b", "c", "d"]) # => true
shape.shape_of?(["a", "b", 1, "d"]) # => false
shape.shape_of?(["a", "b", nil, "d"]) # => false
```

### `ShapeOf::Union`

Pulled from comments from the source code:

> `Union[shape1, shape2, ...]` denotes that it can be of one the provided shapes.

Example:
```ruby
shape = ShapeOf::Union[String, ShapeOf::Array[String]]

shape.shape_of?("") # => true
shape.shape_of?("foo") # => true
shape.shape_of?([]) # => true
shape.shape_of?(["foo", "bar", "baz"]) # => true
shape.shape_of?(["foo", 1]) # => false
shape.shape_of?(nil) # => false
```

### `ShapeOf::Optional`

Pulled from comments from the source code:

> `Optional[shape]` denotes that the usual type is a `shape`, but is optional.
> (meaning if it is `nil` or the key is not present in the `Hash`, it's still true).

Example:
```ruby
shape = ShapeOf::Optional[ShapeOf::Boolean]

shape.shape_of?(nil) # => true
shape.shape_of?(true) # => true
shape.shape_of?(false) # => true
shape.shape_of?(1) # => false
shape.shape_of?("") # => false
```

Example with `ShapeOf::Hash`:
```ruby
shape = ShapeOf::Hash[foo: String, bar: ShapeOf::Optional[ShapeOf::Boolean]]

shape.shape_of?({ foo: "", bar: nil }) # => true
shape.shape_of?({ foo: "", bar: true }) # => true
shape.shape_of?({ foo: "", bar: false }) # => true
shape.shape_of?({ foo: "" }) # => true
shape.shape_of?({ foo: "", bar: 1 }) # => false
shape.shape_of?({ foo: "", bar: "" }) # => false
```

### `ShapeOf::Pattern`

The `ShapeOf::Pattern[/regexp pattern/]` is used to match a `Regexp` against a `String` using `Regexp#match?`.
```ruby
shape = ShapeOf::Pattern[/foobar$/i]

shape.shape_of?("foobar") # => true
shape.shape_of?("fOobAr\n") # => true
shape.shape_of?("\n\nfoobar\n") # => true
shape.shape_of?("foo\nbarfoo\nfoobar\nfo\nobar\n") # => true
shape.shape_of?("There once was a barfoo who foobared. Foobar") # => true
shape.shape_of?("foo\nbar\n") # => false
```

### `ShapeOf::Boolean`

```ruby
ShapeOf::Union[TrueClass, FalseClass]
```

### `ShapeOf::Numeric`

```ruby
ShapeOf::Union[Integer, Float, Rational, Complex]
```

### `ShapeOf::Any`

Anything matches unless key does not exist in the `ShapeOf::Hash`.

### `ShapeOf::Nothing`

Only passes when the key does not exist in the `ShapeOf::Hash`.

## With MiniTest

Included is a `ShapeOf::Assertions` module which includes 2 methods: `assert_shape_of`, and `refute_shape_of`.
Keep in mind that the order of the "expected" and "actual" value for these assertions are backwards of
what Minitest assertions are. In ShapeOf, the actual comes first, then the expected shape comes after.

```Ruby
require 'shape_of'
require 'minitest/autorun'

class MyTestClass < MiniTest::Test
  include ShapeOf::Assertions

  def test_a_shape
    to_test = [{ foo: 1, bar: nil }]
    assert_shape_of(to_test, ShapeOf::Array[
      ShapeOf::Hash[
        foo: Integer,
        bar: ShapeOf::Optional[Integer],
      ]
    ]) # assertion passes
  end
end
```