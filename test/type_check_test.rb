require 'test_helper'
require 'type_check'

class TypeCheckTest < Minitest::Test
  context "TypeCheck" do
    context "has an instance method #check that" do
      setup do
        extend TypeCheck
        @a = 'Test'
        @b = 1
        @arg_types = { :@a => 'String', :@b => 'Integer' }
      end

      should "return an empty array for valid instance variables" do
        assert_equal [], check(binding, @arg_types)
      end

      should "return an empty array for valid local variables" do
        a = 'Test'
        b = 1
        arg_types = { a: 'String', b: 'Integer' }
        assert_equal [], check(binding, arg_types)
        a && b # Hack to avoid the unused variable warning.
      end

      should "raise a TypeError if the first argument isn't of type Binding" do
        invalid_nonbindings = [ nil, Object.new, Array.new ]
        invalid_nonbindings.each do |i|
          assert_raises(TypeError) { check(i, {}) }
        end
      end

      should "raise a TypeError if the arguments are of the wrong type" do
        invalid_inputs = [
          { :@a => 'Integer', :@b => 'Integer' },
          { :@a => 'String', :@b => 'String' },
          { :@a => 'Integer', :@b => 'String' }
        ]
        invalid_inputs.each do |i|
          assert_raises(TypeError) { check(binding, i) }
        end
      end

      should "with the false flag, return array of arguments of wrong type" do
        invalid_inputs = [
          [ [ :@a ], { :@a => 'Integer', :@b => 'Integer' } ],
          [ [ :@b ], { :@a => 'String', :@b => 'String' } ],
          [ [ :@a, :@b ], { :@a => 'Integer', :@b => 'String' } ]
        ]
        invalid_inputs.each do |i|
          assert_equal i[0], check(binding, true, i[1])
        end
      end

      should "raise a NameError if the arguments aren't defined" do
        invalid_names = { :@c => 'String' }
        assert_raises(SyntaxError) { check(binding, invalid_names) }
      end
    end
  end
end