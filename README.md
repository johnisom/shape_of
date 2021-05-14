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

TODO: fill out this section.

### `ShapeOf::Array`

TODO: fill out this section.

### `ShapeOf::Union`

TODO: fill out this section.

### `ShapeOf::Optional`

TODO: fill out this section.

### `ShapeOf::Boolean`

TODO: fill out this section.

### `ShapeOf::Numeric`

TODO: fill out this section.

### `ShapeOf::Any`

TODO: fill out this section.

### `ShapeOf::Nothing`

TODO: fill out this section.

## With MiniTest

```Ruby
require 'shape_of'
require 'minitest/autorun'

class MyTestClass < MiniTest::Test
  include ShapeOf::Assertions

  def test_a_shape
    to_test = [{ foo: 1, bar: nil }]
    assert_shape_of(to_test, ShapeOf::Array[
      ShapeOf::Hash[
        foo: Integer, bar: ShapeOf::Optional[Integer]
      ]
    ]) # assertion passes
  end
end
```