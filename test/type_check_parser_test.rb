require 'test_helper'
require 'type_check'

class TypeCheckParserTest < Minitest::Test
  context "TypeCheck:Parser" do
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
                       'Boolean|Array<String|Hash<Point>|Array<String>>',
                       'Array(len: 5)',
                       'String(format: /woo/)'
                     ]
    end

    context "has a class method .validate that" do
      setup do
        @invalid_strings = ['',
                           '|',
                           '<',
                           '>',
                           '|String',
                           'String|',
                           '<Array',
                           '>Array',
                           'Array<>',
                           'String<',
                           'String>',
                           'Integer<<',
                           'Array<Array<',
                           'Array<Array<String>',
                           'Array<String>>|Array<Array',
                           'Array(len)',
                           'Array(len: )',
                           'Array(len: 5',
                           'Array((len: 5))',
                           'Array(len: 5, (len: 5)| len: 5)',
                           'Array(len: 5, len)',
                           'String(format: /)',
                           'String(format: //)',
                           'String(format: /a/th)']
        @invalid_nonstrings = [nil,
                               Object.new,
                               Array.new]
      end

      should "return nil for valid inputs" do
        @valid_inputs.each do |v|
          assert_nil @Parser.validate(v)
        end
      end

      should "raise a TypeError for non-string parameters" do
        @invalid_nonstrings.each do |i|
          assert_raises(TypeError) { @Parser.validate(i) }
        end
      end

      should "raise a SyntaxError for invalid strings" do
        @invalid_strings.each do |i|
          assert_raises(SyntaxError) { @Parser.validate(i) }
        end
      end
    end

    context "has a class method .parse that" do
      should "return an array of TypeCheck::TypeElement for valid inputs" do
        @valid_inputs.each do |v|
          assert_equal v, TypeCheckParserTest.reverse_parse(@Parser.parse(v))
        end
      end
    end
  end

  def self.reverse_parse(array)
    array.reduce(nil) do |memo, a|
      memo = (memo.nil?) ? '' : memo + '|'
      memo = memo + a.name
      memo = if a.collection.is_a?(Array)
               inner = TypeCheckParserTest.reverse_parse(a.collection)
               memo + '<' + inner + '>'
             else
               memo
             end
      memo = if a.constraints.is_a?(Array)
               inner = a.constraints.reduce(nil) do |cst_memo, c|
                 if cst_memo.nil?
                   cst_memo = c.to_s
                 else
                   cst_memo = cst_memo + ', ' + c.to_s
                 end
               end
               memo + '(' + inner + ')'
             else
               memo
             end
    end
  end
end