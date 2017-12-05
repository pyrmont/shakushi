require 'minitest/autorun'
require 'minitest/reporters'
require 'shoulda/context'
require 'type_check'

# Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
Minitest::Reporters.use!

class TypeCheckParserTest < Minitest::Test
  context "The method TypeCheck::Parser#check_syntax" do
    setup do
      @Parser = TypeCheck::Parser
    end

    should "complete for a class name" do
      inputs = ['String']
      inputs.each do |input|
        assert_nil @Parser.check_syntax(input)
      end
    end

    should "complete for a collection class" do
      inputs = ['Array<String>']
      inputs.each do |input|
        assert_nil @Parser.check_syntax(input)
      end
    end

    should "complete for multiple classes in a class list" do
      inputs = ['String|Float',
                'Array|Hash|Float',
                'Array|Set|Point|Regexp']
      inputs.each do |input|
        assert_nil @Parser.check_syntax(input)
      end
    end

    should "complete for nested collections of classes" do
      inputs = ['Array<Array<String>>',
                'Array<Array<Array<String>>>']
      inputs.each do |input|
        assert_nil @Parser.check_syntax(input)
      end
    end

    should "complete for combinations of lists and collections" do
      inputs = ['String|Array<Integer>',
                'Array<Integer>|String',
                'String|Integer|Array<Hash<Object>>',
                'String|Array<String|Integer>|Object',
                'Boolean|Array<String|Hash<Point>|Array<String>>']
      inputs.each do |input|
        assert_nil @Parser.check_syntax(input)
      end
    end

    should "fail for a class name ending in <" do
      inputs = ['String<',
                'Integer<<',
                'Array<Array<']
      inputs.each do |input|
        assert_raises(SyntaxError) { @Parser.check_syntax(input) }
      end
    end

    should "fail for an unbalanced <>" do
      inputs = ['Array<Array<String>']
      inputs.each do |input|
        assert_raises(SyntaxError) { @Parser.check_syntax(input) }
      end
    end
  end

  context "The method TypeCheck::Parser#parse" do
    setup do
      @Parser = TypeCheck::Parser
      @ClassElement = TypeCheck::ClassElement
    end

    should "complete for a class name" do
      inputs = ['String']
      outputs = [[@ClassElement.new(name: 'String')]]
      inputs.each_with_index do |input, i|
        assert_equal @Parser.parse(input), outputs[i]
      end
    end

    should "complete for a collection class" do
      inputs = ['Array<String>']
      outputs = [[@ClassElement.new(
                    name: 'Array',
                    collection: [@ClassElement.new(name: 'String')]
                  )]]
      inputs.each_with_index do |input, i|
        assert_equal @Parser.parse(input), outputs[i]
      end
    end
  end
end