require 'test_helper'
require 'type_check'

class TypeCheckTypeElementTest < Minitest::Test
  context "TypeCheck::TypeElement" do
    context "has an instance method #initialize that" do
      setup do
        @valid_name = 'Array'
      end

      should "initialise with a valid class name" do
        te = TypeCheck::TypeElement.new(name: @valid_name)
        assert_kind_of TypeCheck::TypeElement, te
      end

      should "initialise with a valid class name and child type" do
        component = TypeCheck::TypeElement.new(name: 'Integer')
        ct = TypeCheck::TypeElement::ChildType.new([component])
        te = TypeCheck::TypeElement.new(name: @valid_name, child_type: ct)
        assert_kind_of TypeCheck::TypeElement, te
      end

      should "initialise with a valid class name, child type and constraints" do
        component = TypeCheck::TypeElement.new(name: 'Integer')
        child_type = TypeCheck::TypeElement::ChildType.new([component])
        constraint = TypeCheck::TypeElement::Constraint.new(name: 'min',
                                                            value: '0')
        te = TypeCheck::TypeElement.new(name: @valid_name,
                                        child_type: child_type,
                                        constraints: [constraint])
        assert_kind_of TypeCheck::TypeElement, te
      end

      should "raise an ArgumentError if argument 'name' is an empty string" do
        invalid_name = ''
        assert_raises(ArgumentError) do
          TypeCheck::TypeElement.new(name: invalid_name)
        end
      end

      should "raise an ArgumentError if argument 'child_type' is empty" do
        invalid_child_type = TypeCheck::TypeElement::ChildType.new
        assert_raises(ArgumentError) do
          TypeCheck::TypeElement.new(name: @valid_name,
                                     child_type: invalid_child_type)
        end
      end

      should "raise an ArgumentError if argument 'constraints' is empty" do
        invalid_constraints = []
        assert_raises(ArgumentError) do
          TypeCheck::TypeElement.new(name: @valid_name,
                                     constraints: invalid_constraints)
        end
      end

      should "raise a TypeError if arguments are incorrectly typed" do
        invalid_names = [ nil, Object.new, Array.new ]
        invalid_names.each do |i|
          assert_raises(TypeError) { TypeCheck::TypeElement.new(name: i) }
        end

        invalid_child_types = [ Object.new, String.new ]
        invalid_child_types.each do |i|
          assert_raises(TypeError) do
            TypeCheck::TypeElement.new(name: @valid_name, child_type: i)
          end
        end

        invalid_constraints = [ Object.new, String.new ]
        invalid_constraints.each do |i|
          assert_raises(TypeError) do
            TypeCheck::TypeElement.new(name: @valid_name, constraints: i)
          end
        end
      end
    end

    context "has an instance method #== that" do
      setup do
        @class_name = 'Integer'
        @te = TypeCheck::TypeElement.new(name: @class_name)
      end

      should "return true for a valid matching input" do
        same_comp = TypeCheck::TypeElement.new(name: @class_name)
        assert_equal (@te == same_comp), true
      end

      should "return false for a valid non-matching input" do
        other_class_name = 'Hash'
        diff_comp = TypeCheck::TypeElement.new(name: other_class_name)
        assert_equal (@te == diff_comp), false
      end

      should "raise a TypeError when comparator is wrong type" do
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
        type_defs = YAML.load_file 'test/data/valid_type_defs.yml'
        @types = TypeCheckTestHelper.create_types type_defs
      end

      should "return true for a match" do
        valid_args = YAML.load_file 'test/data/valid_args.yml'
        valid_args.each.with_index do |v,index|
          assert (@types[index].any? { |t| t.match?(v) == true } )
        end
      end

      should "return false for a failed match" do
        invalid_args = YAML.load_file 'test/data/invalid_args.yml'
        invalid_args.each.with_index do |i,index|
          assert (@types[index].any? { |t| t.match?(i) == false } )
        end
      end
    end
  end
end