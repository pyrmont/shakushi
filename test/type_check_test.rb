require 'test_helper'
require 'type_check'

class TypeCheckTest < Minitest::Test
  context "TypeCheck" do
    context "has an instance method #check that" do
      setup do
        extend TypeCheck
      end

      should "return a hash of the arguments for valid inputs" do
        a = 'Test'
        b = 1
        args = { a: 'String', b: 'Integer' }
        assert_equal check(binding, args), args
        a, b = true # This is a hack to avoid the unused variable warning.
      end

      should "raise a TypeError if the first argument isn't of type Binding" do
        invalid_nonbindings = [ nil, Object.new, Array.new ]
        invalid_nonbindings.each do |i|
          assert_raises(TypeError) { check(i, {}) }
        end
      end

      should "raise a TypeError if the arguments aren't of the right type" do
        a = 'Test'
        b = 1
        args = { a: 'Integer', b: 'String' }
        assert_raises(TypeError) { check(binding, args) }
        a, b = true # This is a hack to avoid the unused variable warning.
      end
    end
  end
end