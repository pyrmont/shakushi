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
        invalid_names = [ nil, Object.new, Array ]
        invalid_names.each do |i|
          assert_raises(TypeError) { TypeCheck::TypeElement.new(name: i) }
        end

        invalid_children = [ Object.new, String.new ]
        invalid_children.each do |i|
          assert_raises(TypeError) do
            TypeCheck::TypeElement.new(name: @valid_name, children: i)
          end
        end
      end
    end

    context "has an instance method #== that" do
      setup do
        @valid_name = 'Test'
        @other_valid_name = 'Test 2'
        @te = TypeCheck::TypeElement.new(name: @valid_name)
      end

      should "return true or false for valid input" do
        diff_comp = TypeCheck::TypeElement.new(name: @other_valid_name)
        same_comp = TypeCheck::TypeElement.new(name: @valid_name)
        assert_equal (@te == diff_comp), false
        assert_equal (@te == same_comp), true
      end

      should "raise a TypeError when the object to be compared is wrong type" do
        invalid_comparisons = [ nil, Object.new, Array.new ]
        invalid_comparisons.each do |i|
          assert_raises(TypeError) { @te == i }
        end
      end
    end

    context "has an instance method #constraint= that" do
      setup do
        @te = TypeCheck::TypeElement.new(name: 'String')
      end

      should "set the constraints for valid input" do
        csts = [ TypeCheck::TypeElement::Constraint.new(name: 'min', value: 1),
                 TypeCheck::TypeElement::Constraint.new(name: 'max', value: 5) ]
        @te.constraints = csts
        assert_equal (@te.constraints == csts), true
      end

      should "raise a TypeError when the argument is not an Array" do
        invalid_comparisons = [ nil, Object.new, Hash.new ]
        invalid_comparisons.each do |i|
          assert_raises(TypeError) { @te.constraints = i }
        end
      end

      should "raise a SyntaxError when there duplicate constraints" do
        csts = [ TypeCheck::TypeElement::Constraint.new(name: 'min', value: 1),
                 TypeCheck::TypeElement::Constraint.new(name: 'min', value: 5) ]
        assert_raises(SyntaxError) { @te.constraints = csts }
      end
    end

    context "has an instance method #match? that" do
      setup do
        csts = [ TypeCheck::TypeElement::Constraint.new(name: 'min', value: 1),
                 TypeCheck::TypeElement::Constraint.new(name: 'max', value: 5) ]
        children = [ TypeCheck::TypeElement.new(name: 'String',
                                                constraints: csts) ]
        @te = TypeCheck::TypeElement.new(name: 'Array',
                                         children: children,
                                         constraints: csts)
      end

      should "return true for a match" do
        arg = [ 'Test' ]
        assert (@te.match?(arg) == true)
      end

      should "return false for a failed match" do
        invalid_inputs = [ [ 3 ], [ 'Testing' ], 3, 'Test' ]
        invalid_inputs.each do |i|
          assert (@te.match?(i) == false)
        end
      end
    end
  end
end