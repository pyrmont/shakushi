require 'test_helper'
require 'type_check'

class TypeCheckClassElementTest < Minitest::Test
  context "TypeCheck::ClassElement" do
    context "has an instance method #initialize that" do
      setup do
        @valid_name = 'Test'
      end

      should "return a TypeCheck::ClassElement when initialised correctly" do
        ce = TypeCheck::ClassElement.new(name: @valid_name)
        assert_kind_of TypeCheck::ClassElement, ce
      end

      should "raise an ArgumentError when initialised with an empty string" do
        invalid_name = ''
        assert_raises(ArgumentError) do
          TypeCheck::ClassElement.new(name: invalid_name)
        end
      end

      should "raise a TypeError when initialised with wrong typed arguments" do
        invalid_names = [nil, Object.new, Array]
        invalid_names.each do |i|
          assert_raises(TypeError) { TypeCheck::ClassElement.new(name: i) }
        end

        invalid_collections = [Object.new, String.new]
        invalid_collections.each do |i|
          assert_raises(TypeError) do
            TypeCheck::ClassElement.new(name: @valid_name, collection: i)
          end
        end
      end
    end

    context "has an instance method #== that" do
      setup do
        @valid_name = 'Test'
        @other_valid_name = 'Test 2'
        @ce = TypeCheck::ClassElement.new(name: @valid_name)
      end

      should "return true or false for valid input" do
        comp = TypeCheck::ClassElement.new(name: @other_valid_name)
        assert_equal (@ce == comp), false
      end

      should "raise a TypeError when the object to be compared is wrong type" do
        invalid_comparisons = [nil, Object.new, Array.new]
        invalid_comparisons.each do |i|
          assert_raises(TypeError) { @ce == i }
        end
      end
    end
  end
end