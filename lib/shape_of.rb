# Copyright 2021 John Isom.
# Licensed under the open source MIT license.

# The ShapeOf module can be used in testing JSON APIs to make sure that
# the body of the result is of the correct format. It is similar to a type
# checker, but a bit more generic.
#
# For example, given this hash, where `friendly_name`, `external_id`, `external_avatar_url`, and `data` are optional:
# ```ruby
# hash = {
#   id: 123,
#   name: "John Doe",
#   friendly_name: "Johnny",
#   external_id: "",
#   external_avatar_url: "https://example.com/avatar.jpg",
#   data: {
#     status: "VIP"
#   },
#   identities: [
#     {
#       id: 1,
#       type: "email",
#       identifier: "john37@example.com"
#     }
#   ],
#   created_at: "2020-12-28T15:55:35.121Z",
#   updated_at: "2020-12-28T15:55:35.121Z"
# }
# ```

# the proper shape would be this:
# ```ruby
# shape = ShapeOf::Hash[
#   id: Integer,
#   name: String,
#   friendly_name: ShapeOf::Optional[String],
#   external_id: ShapeOf::Optional[String],
#   external_avatar_url: ShapeOf::Optional[String],
#   data: ShapeOf::Optional[Hash],
#   identities: ShapeOf::Array[
#     ShapeOf::Hash[
#       id: Integer,
#       type: String,
#       identifier: String
#     ]
#   ],
#   created_at: String,
#   updated_at: String
# ]

# shape.shape_of? hash # => true
# ```

# As another example, given this shape:
# ```ruby
# hash_shape = ShapeOf::Hash[
#   value: ShapeOf::Optional[
#     ShapeOf::Union[
#       ShapeOf::Array[
#         ShapeOf::Hash[
#           inner_value: ShapeOf::Any
#         ]
#       ],
#       ShapeOf::Hash[
#         inner_value: ShapeOf::Any
#       ]
#     ]
#   ]
# ]
# ```

# These shapes pass:
# ```ruby
# hash_shape.shape_of?({ value: { inner_value: 3 } }) # => true
# hash_shape.shape_of?({ value: [{ inner_value: 3 }] }) # => true
# hash_shape.shape_of?({ value: [{ inner_value: 3 }, { inner_value: "foo" }, { inner_value: [1, 2, 3] }] }) # => true
# ```

# And these fail:
# ```ruby
# hash_shape.shape_of?({ foo: { inner_value: 'bar' } }) # => false
# hash_shape.shape_of?({ value: 23 }) # => false
# hash_shape.shape_of?({ value: [23] }) # => false
# hash_shape.shape_of?({ value: [{}] }) # => false
# ```
#
module ShapeOf
  # To be included in a MiniTest test class
  module Assertions
    def assert_shape_of(object, shape)
      if shape.respond_to? :shape_of?
        assert_operator shape, :shape_of?, object
      elsif shape.instance_of? ::Array
        assert_operator Array[shape.first], :shape_of?, object
      elsif shape.instance_of? ::Hash
        assert_operator Hash[shape], :shape_of?, object
      else
        raise TypeError, "Expected #{Shape.inspect}, an #{::Array.inspect}, or a #{::Hash.inspect} as the shape"
      end
    end

    def refute_shape_of(object, shape)
      if shape.respond_to? :shape_of?
        refute_operator shape, :shape_of?, object
      elsif shape.instance_of? ::Array
        refute_operator Array[shape.first], :shape_of?, object
      elsif shape.instance_of? ::Hash
        refute_operator Hash[shape], :shape_of?, object
      else
        raise TypeError, "Expected #{Shape.inspect}, an #{::Array.inspect}, or a #{::Hash.inspect} as the shape"
      end
    end
  end

  # Generic shape which all shapes subclass from
  class Shape
    def self.shape_of?(*)
      raise NotImplementedError
    end

    def self.required?
      true
    end

    def initialize(*)
      raise NotImplementedError
    end
  end

  # Array[Shape] denotes that it is an array of shapes.
  # It checks every element in the array and verifies that the element is in the correct shape.
  # This, along with Array, are the core components of this module.
  # Note that a ShapeOf::Array[Integer].shape_of?([]) will pass because it is vacuously true for an empty array.
  class Array < Shape
    @internal_class = ::Array

    def self.shape_of?(object)
      object.instance_of? @internal_class
    end

    def self.[](shape)
      Class.new(self) do
        @class_name = "#{superclass.name}[#{shape.inspect}]"
        @shape = shape
        @internal_class = superclass.instance_variable_get(:@internal_class)

        def self.name
          @class_name
        end

        def self.to_s
          @class_name
        end

        def self.inspect
          @class_name
        end

        def self.shape_of?(array)
          super && array.all? do |elem|
            if @shape.respond_to? :shape_of?
              @shape.shape_of? elem
            elsif @shape.is_a? ::Array
              Array[@shape].shape_of? elem
            elsif @shape.is_a? ::Hash
              Hash[@shape].shape_of? elem
            elsif @shape.is_a? Class
              elem.instance_of? @shape
            else
              elem == @shape
            end
          end
        end
      end
    end
  end

  # Hash[key: Shape, ...] denotes it is a hash of shapes with a very specific structure. Hash (without square brackets) is just a hash with any shape.
  # This, along with Array, are the core components of this module.
  # Note that the keys are converted to strings for comparison for both the shape and object provided.
  class Hash < Shape
    @internal_class = ::Hash

    def self.shape_of?(object)
      object.instance_of? @internal_class
    end

    def self.[](shape = {})
      raise TypeError, "Shape must be Hash, was #{shape.class.name}" unless shape.instance_of? ::Hash

      Class.new(self) do
        @class_name = "#{superclass.name}[#{shape.map { |(k, v)| "#{k.to_s}: #{v.inspect}" }.join(', ')}]"
        @shape = stringify_rb_hash_keys(shape)
        @internal_class = superclass.instance_variable_get(:@internal_class)

        def self.name
          @class_name
        end

        def self.to_s
          @class_name
        end

        def self.inspect
          @class_name
        end

        def self.shape_of?(hash)
          return false unless super

          rb_hash = stringify_rb_hash_keys(hash)

          rb_hash.keys.each do |key|
            return false unless @shape.key?(key)
          end

          @shape.each do |key, shape|
            return false unless rb_hash.key?(key) || shape.respond_to?(:required?) && !shape.required?
          end

          rb_hash.all? do |key, elem|
            if @shape[key].respond_to? :shape_of?
              @shape[key].shape_of? elem
            elsif @shape[key].is_a? ::Array
              Array[@shape[key]].shape_of? elem
            elsif @shape[key].is_a? ::Hash
              Hash[@shape[key]].shape_of? elem
            elsif @shape[key].is_a? Class
              elem.instance_of? @shape[key]
            else
              elem == @shape[key]
            end
          end
        end
      end
    end

    private

    def self.stringify_rb_hash_keys(rb_hash)
      rb_hash.to_a.map { |k, v| [k.to_s, v] }.to_h
    end
  end

  # Union[Shape1, Shape2, ...] denotes that it can be of one the provided shapes
  class Union < Shape
    def self.shape_of?(object)
      false
    end

    def self.[](*shapes)
      Class.new(self) do
        @class_name = "#{superclass.name}[#{shapes.map(&:inspect).join(", ")}]"
        @shapes = shapes

        def self.name
          @class_name
        end

        def self.to_s
          @class_name
        end

        def self.inspect
          @class_name
        end

        def self.shape_of?(object)
          @shapes.any? do |shape|
            if shape.respond_to? :shape_of?
              shape.shape_of? object
            elsif shape.is_a? ::Hash
              Hash[shape].shape_of? object
            elsif shape.is_a? ::Array
              Array[shape].shape_of? object
            elsif shape.is_a? Class
              object.instance_of? shape
            else
              object == shape
            end
          end
        end
      end
    end
  end

  # Optional[Shape] denotes that the usual type is a Shape, but is optional (meaning if it is nil or the key is not present in the Hash, it's still true)
  class Optional < Shape
    def self.[](shape)
      raise TypeError, "Shape cannot be nil" if shape.nil? || shape == NilClass

      Union[shape, NilClass].tap do |this|
        new_class_name = this.name.sub('Union', 'Optional').sub(/(?<=\[).*(?=\])/, shape.inspect)
        this.instance_variable_set(:@class_name, new_class_name)
        def this.required?
          false
        end
      end
    end

    def self.required?
      false
    end
  end

  class Any < Shape
    def self.shape_of?(object)
      true
    end
  end

  # Nothing only passes when the key does not exist in the Hash.
  class Nothing < Shape
    def self.shape_of?(object)
      false
    end

    def self.required?
      false
    end
  end

  Numeric = Union[Integer, Float, Rational, Complex].tap do |this|
    this.instance_variable_set(:@class_name, this.name.sub(/Union.*/, 'Numeric'))
  end

  Boolean = Union[TrueClass, FalseClass].tap do |this|
    this.instance_variable_set(:@class_name, this.name.sub(/Union.*/, 'Boolean'))
  end
end

# Monkey patch
class Hash
  def to_shape_of
    ShapeOf::Hash[self]
  end
end

# Monkey patch
class Array
  def to_shape_of
    ShapeOf::Array[self.first]
  end
end