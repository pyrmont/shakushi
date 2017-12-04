require 'minitest/autorun'
require 'minitest/reporters'
require 'shoulda/context'
require 'type_check'

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

class TypeCheckParserTest < Minitest::Test
  context "The TypeCheck Parser" do
    setup do
      @Parser = TypeCheck::Parser
    end

    should "complete the syntax check for a class name" do
      inputs = ['String']
      inputs.each do |i|
        assert_nil @Parser.check_syntax(i)
      end
    end

    should "complete the syntax check for a collection class" do
      inputs = ['Array<String>']
      inputs.each do |i|
        assert_nil @Parser.check_syntax(i)
      end
    end

    should "complete the syntax check for multiple classes in a class list" do
      inputs = ['String|Float',
                'Array|Hash|Float',
                'Array|Set|Point|Regexp']
      inputs.each do |i|
        assert_nil @Parser.check_syntax(i)
      end
    end

    should "complete the syntax check for recursive collections" do
      inputs = ['Array<Array<Array<String>>>']
      inputs.each do |i|
        assert_nil @Parser.check_syntax(i)
      end
    end

    should "fail the syntax check for a class name ending in <" do
      inputs = ['String<',
                'Integer<<',
                'Array<Array<']
      inputs.each do |i|
        assert_raises(SyntaxError) { @Parser.check_syntax(i) }
      end
    end

    should "fail the syntax check for an unbalanced <>" do
      inputs = ['Array<Array<String>']
      inputs.each do |i|
        assert_raises(SyntaxError) { @Parser.check_syntax(i) }
      end
    end
  end
end