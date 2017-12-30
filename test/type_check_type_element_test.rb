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
            TypeCheck::TypeElement.new(name: @valid_name, child_type: i)
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
        type_defs = [ # Integer
                      [ { class: 'Integer' } ],
                      # String|Integer
                      [ { class: 'String' }, { class: 'Integer' } ],
                      # Array<String(min: 3)>(max: 10)
                      [ { class: 'Array',
                          child_type: [
                            [ { class: 'String', constraints: 'min: 3' } ]
                          ],
                          constraints: 'max: 10' } ],
                      # Hash<Symbol,Integer(max: 100)>
                      [ { class: 'Hash',
                          child_type: [
                            [ { class: 'Symbol' } ],
                            [ { class: 'Integer', constraints: 'max: 100' } ]
                          ] } ],
                      # String(len: 5)
                      [ { class: 'String', constraints: 'len: 5' } ],
                      # Integer(val: 3)
                      [ { class: 'Integer', constraints: 'val: 3' } ],
                      # String(val: "This will match.")
                      [ { class: 'String',
                          constraints: 'val: "This will match."' } ] ]
        @types = TypeCheckTypeElementTest.create_types type_defs
      end

      should "return true for a match" do
        valid_args = [ 99, 1, [ 'Test' ], { test: 1 }, 'Tests', 3,
                       'This will match.' ]
        valid_args.each.with_index do |v,index|
          assert (@types[index].any? { |t| t.match?(v) == true } )
        end
      end

      should "return false for a failed match" do
        invalid_args = [ 'Not Integer', 3.14, [ 3 ], { test: 'Testing' },
                         'Test', 2, 'This will not match.' ]
        invalid_args.each.with_index do |i,index|
          assert (@types[index].any? { |t| t.match?(i) == false } )
        end
      end
    end
  end

  def self.create_types(type_defs)
    type_defs.reduce([]) do |types,type_def|
      res = type_def.reduce([]) do |memo_t,t|
              ct = (t[:child_type]) ? TypeCheck::TypeElement::ChildType.new(
                                        create_types(t[:child_type])) :
                                      nil
              csts = t[:constraints]&.split(', ')&.reduce([]) do |memo_c,c|
                       pieces = c.split(': ')
                       cst = TypeCheck::TypeElement::Constraint.new(
                         name: pieces[0],
                         value: pieces[1])
                       memo_c.push cst
                     end
              memo_t.push TypeCheck::TypeElement.new(name: t[:class],
                                                     child_type: ct,
                                                     constraints: csts)
            end
      types.push res
    end
  end
end