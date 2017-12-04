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
      assert_nil @Parser.check_syntax('String')
    end

    should "complete the syntax check for a collection class" do
      assert_nil @Parser.check_syntax('Array<String>')
    end

    should "complete the syntax check for multiple classes in a class list" do
      assert_nil @Parser.check_syntax('String|Float')
      assert_nil @Parser.check_syntax('Array|Hash|Float')
      assert_nil @Parser.check_syntax('Array|Set|Point|Regexp')
    end

    should "complete the syntax check for recursive collections" do
      assert_nil @Parser.check_syntax('Array<Array<Array<String>>>')
    end

    should "fail the syntax check for a class name ending in <" do
      assert_raises(SyntaxError) { @Parser.check_syntax('String<') }
    end
  end
end