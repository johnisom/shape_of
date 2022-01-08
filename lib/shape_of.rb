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
require 'pp'

module ShapeOf
  class Validator
    attr_reader :shape, :object

    def initialize(shape:, object:)
      @current_error_key_nesting = [:base] # stack of the current error key
      @errors = {}
      @object = object
      @shape = shape

      validate
    end

    def valid?
      @errors.empty?
    end

    def error_message
      @errors.pretty_inspect
    end

    def add_error(message)
      create_nested_error_structure

      @errors.dig(*@current_error_key_nesting)[:errors] << message.dup
    end

    def push_key(key)
      @current_error_key_nesting.push(key)
    end

    def pop_key
      @current_error_key_nesting.pop
    end

    private

    def create_nested_error_structure
      errors = @errors
      @current_error_key_nesting.each do |key|
        errors[key] ||= {}
        errors = errors[key]
      end
      @errors.dig(*@current_error_key_nesting)[:errors] ||= []
    end

    def validate
      shape.shape_of?(object, validator: self)
    end
  end

  # To be included in a MiniTest test class
  module Assertions
    def assert_shape_of(object, shape)
      validator = nil
      if shape.respond_to? :shape_of?
        validator = Validator.new(shape: shape, object: object)
      elsif shape.instance_of? ::Array
        validator = Validator.new(shape: Array[shape.first], object: object)
      elsif shape.instance_of? ::Hash
        validator = Validator.new(shape: Hash[shape], object: object)
      else
        raise TypeError, "Expected #{Shape.inspect}, an #{::Array.inspect}, or a #{::Hash.inspect} as the shape"
      end

      assert validator.valid?, validator.error_message
    end

    def refute_shape_of(object, shape)
      validator = nil
      if shape.respond_to? :shape_of?
        validator = Validator.new(shape: shape, object: object)
      elsif shape.instance_of? ::Array
        validator = Validator.new(shape: Array[shape.first], object: object)
      elsif shape.instance_of? ::Hash
        validator = Validator.new(shape: Hash[shape], object: object)
      else
        raise TypeError, "Expected #{Shape.inspect}, an #{::Array.inspect}, or a #{::Hash.inspect} as the shape"
      end

      refute validator.valid?, "#{shape} is shape_of? #{object}"
    end
  end

  # Generic shape which all shapes subclass from
  class Shape
    def self.shape_of?(object, validator: Validator.new(shape: self, object: object))
      raise NotImplementedError
    end

    def self.required?
      true
    end

    def initialize(*)
      raise NotImplementedError
    end
  end

  # Array[shape] denotes that it is an array of shapes.
  # It checks every element in the array and verifies that the element is in the correct shape.
  # This, along with Hash, are the core components of this module.
  # Note that a ShapeOf::Array[Integer].shape_of?([]) will pass because it is vacuously true for an empty array.
  class Array < Shape
    @internal_class = ::Array

    def self.shape_of?(object, validator: Validator.new(shape: self, object: object))
      is_instance_of = object.instance_of?(@internal_class)
      validator.add_error(object.inspect + " is not instance of " + @internal_class.inspect) unless is_instance_of

      is_instance_of
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

        def self.shape_of?(array, validator: Validator.new(shape: self, object: array))
          idx = 0
          each_is_shape_of = true
          super && array.each do |elem|
            validator.push_key("idx_" + idx.to_s)

            is_shape_of = if @shape.respond_to? :shape_of?
              @shape.shape_of?(elem, validator: validator)
            elsif @shape.is_a? ::Array
              Array[@shape.first].shape_of?(elem, validator: validator)
            elsif @shape.is_a? ::Hash
              Hash[@shape].shape_of?(elem, validator: validator)
            elsif @shape.is_a? Class
              is_instance_of = elem.instance_of?(@shape)
              validator.add_error(elem.inspect + " is not instance of " + @shape.inspect) unless is_instance_of

              is_instance_of
            else
              is_equal_to = elem == @shape
              validator.add_error(elem.inspect " is not equal to (==) " + @shape.inspect) unless is_equal_to

              is_equal_to
            end

            validator.pop_key
            idx += 1
            each_is_shape_of &&= is_shape_of
          end
          each_is_shape_of
        end
      end
    end
  end

  # Hash[key: shape, ...] denotes it is a hash of shapes with a very specific structure.
  # Hash (without square brackets) is just a hash with any shape.
  # This, along with Array, are the core components of this module.
  # Note that the keys are converted to strings for comparison for both the shape and object provided.
  class Hash < Shape
    @internal_class = ::Hash

    def self.shape_of?(object, validator: Validator.new(shape: self, object: object))
      is_instance_of = object.instance_of?(@internal_class)
      validator.add_error(object.inspect + " is not instance of " + @internal_class.inspect) unless is_instance_of

      is_instance_of
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

        def self.shape_of?(hash, validator: Validator.new(shape: self, object: hash))
          return false unless super

          rb_hash = stringify_rb_hash_keys(hash)

          rb_hash.keys.each do |key|
            has_key = @shape.key?(key)
            unless has_key
              validator.push_key(key)
              validator.add_error("unexpected key")
              validator.pop_key
              return false
            end
          end

          @shape.each do |key, shape|
            unless rb_hash.key?(key) || shape.respond_to?(:required?) && !shape.required?
              validator.push_key(key)
              validator.add_error("required key not present")
              validator.pop_key
              return false
            end
          end

          each_is_shape_of = true
          rb_hash.each do |key, elem|
            shape_elem = @shape[key]
            validator.push_key(key)

            is_shape_of = if shape_elem.respond_to? :shape_of?
              shape_elem.shape_of?(elem, validator: validator)
            elsif shape_elem.is_a? ::Array
              Array[shape_elem.first].shape_of?(elem, validator: validator)
            elsif shape_elem.is_a? ::Hash
              Hash[shape_elem].shape_of?(elem, validator: validator)
            elsif shape_elem.is_a? Class
              is_instance_of = elem.instance_of?(shape_elem)
              validator.add_error(elem.inspect + " is not instance of " + shape_elem.inspect) unless is_instance_of

              is_instance_of
            else
              is_equal_to = elem == shape_elem
              validator.add_error(elem.inspect " is not equal to (==) " + shape_elem.inspect) unless is_equal_to

              is_equal_to
            end

            validator.pop_key
            each_is_shape_of &&= is_shape_of
          end
          each_is_shape_of
        end
      end
    end

    private

    def self.stringify_rb_hash_keys(rb_hash)
      rb_hash.transform_keys(&:to_s)
    end
  end

  # Union[shape1, shape2, ...] denotes that it can be of one the provided shapes.
  class Union < Shape
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

        def self.shape_of?(object, validator: Validator.new(shape: self, object: object))
          is_any_shape_of_shape_or_hash_or_array = false
          is_any_shape_of = @shapes.any? do |shape|
            if shape.respond_to? :shape_of?
              is_shape_of = shape.shape_of?(object, validator: validator)
              is_any_shape_of_shape_or_hash_or_array ||= is_shape_of
            elsif shape.is_a? ::Hash
              is_shape_of = Hash[shape].shape_of?(object, validator: validator)
              is_any_shape_of_shape_or_hash_or_array ||= is_shape_of
            elsif shape.is_a? ::Array
              is_shape_of = Array[shape].shape_of?(object, validator: validator)
              is_any_shape_of_shape_or_hash_or_array ||= is_shape_of
            elsif shape.is_a? Class
              object.instance_of?(shape)
            else
              object == shape
            end
          end

          if !is_any_shape_of && !is_any_shape_of_shape_or_hash_or_array
            class_shapes = @shapes.select do |shape|
              !shape.respond_to?(:shape_of?) && !shape.is_a?(::Hash) && !shape.is_a?(::Array) && shape.is_a?(Class)
            end
            object_shapes = @shapes.select do |shape|
              !shape.respond_to?(:shape_of?) && !shape.is_a?(::Hash) && !shape.is_a?(::Array) && !shape.is_a?(Class)
            end
            validator.add_error(object.inspect + " not instance of any of (" + class_shapes.map(&:inspect).join(", ") +
                                ") or is not equal to (==) any of (" + object_shapes.map(&:inspect).join(", ") + ")")
          end

          is_any_shape_of
        end
      end
    end
  end

  # Optional[shape] denotes that the usual type is a shape, but is optional
  # (meaning if it is nil or the key is not present in the Hash, it's still true)
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

  # Anything matches unless key does not exist in the Hash.
  class Any < Shape
    def self.shape_of?(object, validator: Validator.new(shape: self, object: object))
      true
    end
  end

  # Only passes when the key does not exist in the Hash.
  class Nothing < Shape
    def self.shape_of?(object, validator: Validator.new(shape: self, object: object))
      validator.add_error("key present when not allowed")
      false
    end

    def self.required?
      false
    end
  end

  # Matches a Regexp against a String using Regexp#match?.
  # Pretty much a wrapper around Regexp because a Regexp instance will be tested for equality
  # in the ShapeOf::Hash and ShapeOf::Array since it's not a class.
  class Pattern < Shape
    def self.[](shape)
      raise TypeError, "Shape must be #{Regexp.inspect}, was #{shape.inspect}" unless shape.instance_of? Regexp

      Class.new(self) do
        @class_name = "#{superclass.name}[#{shape.inspect}]"
        @shape = shape

        def self.name
          @class_name
        end

        def self.to_s
          @class_name
        end

        def self.inspect
          @class_name
        end

        def self.shape_of?(object, validator: Validator.new(shape: self, object: object))
          raise TypeError, "expected #{String.inspect}, was instead #{object.inspect}" unless object.instance_of?(String)

          does_regexp_match = @shape.match?(object)
          validator.add_error(object.inspect + " does not match " + @shape.inspect) unless does_regexp_match
          does_regexp_match
        end
      end
    end
  end

  # Union[Integer, Float, Rational, Complex]
  Numeric = Union[Integer, Float, Rational, Complex].tap do |this|
    this.instance_variable_set(:@class_name, this.name.sub(/Union.*/, 'Numeric'))
  end

  # Union[TrueClass, FalseClass]
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