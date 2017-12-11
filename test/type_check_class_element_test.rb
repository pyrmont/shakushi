require 'test_helper'
require 'type_check'

class TypeCheckTypeElementTest < Minitest::Test
  context "TypeCheck::TypeElement" do
    context "has an instance method #initialize that" do
      setup do
        @valid_name = 'Test'
      end

      should "return a TypeCheck::TypeElement when initialised correctly" do
        ce = TypeCheck::TypeElement.new(name: @valid_name)
        assert_kind_of TypeCheck::TypeElement, ce
      end

      should "raise an ArgumentError when initialised with an empty string" do
        invalid_name = ''
        assert_raises(ArgumentError) do
          TypeCheck::TypeElement.new(name: invalid_name)
        end
      end

      should "raise a TypeError when initialised with wrong typed arguments" do
        invalid_names = [nil, Object.new, Array]
        invalid_names.each do |i|
          assert_raises(TypeError) { TypeCheck::TypeElement.new(name: i) }
        end

        invalid_collections = [Object.new, String.new]
        invalid_collections.each do |i|
          assert_raises(TypeError) do
            TypeCheck::TypeElement.new(name: @valid_name, collection: i)
          end
        end
      end
    end

    context "has an instance method #== that" do
      setup do
        @valid_name = 'Test'
        @other_valid_name = 'Test 2'
        @ce = TypeCheck::TypeElement.new(name: @valid_name)
      end

      should "return true or false for valid input" do
        comp = TypeCheck::TypeElement.new(name: @other_valid_name)
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