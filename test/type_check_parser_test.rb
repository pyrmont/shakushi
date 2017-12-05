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
      @valid_inputs = ['String',
                       'Array<String>',
                       'String|Float',
                       'Array|Hash|Float',
                       'Array|Set|Point|Regexp',
                       'Array<Array<String>>',
                       'Array<Array<Array<String>>>',
                       'String|Array<Integer>',
                       'Array<Integer>|String',
                       'String|Integer|Array<Hash<Object>>',
                       'String|Array<String|Integer>|Object',
                       'Boolean|Array<String|Hash<Point>|Array<String>>']
      @invalid_inputs = ['String<',
                         'Integer<<',
                         'Array<Array<',
                         'Array<Array<String>']
    end

    should "return nil for valid inputs" do
      @valid_inputs.each do |v|
        assert_nil @Parser.check_syntax(v)
      end
    end

    should "raise syntax error for invalid inputs" do
      @invalid_inputs.each do |i|
        assert_raises(SyntaxError) { @Parser.check_syntax(i) }
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