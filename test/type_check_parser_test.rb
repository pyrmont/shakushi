require 'test_helper'
require 'type_check'

class TypeCheckParserTest < Minitest::Test
  context "TypeCheck:Parser" do
    setup do
      @Parser = TypeCheck::Parser
      @valid_inputs =
        [ 'String',
          'Array<String>',
          'Hash<Symbol,String>',
          'Collection<Integer,String,Array<Integer>>',
          'String|Float',
          'Array|Hash|Float',
          'Array|Set|Point|Regexp',
          'Array<Array<String>>',
          'Array<Array<Array<String>>>',
          'String|Array<Integer>',
          'Array<Integer>|String',
          'String|Integer|Array<Hash<Symbol,Object>>',
          'String|Array<String|Integer>|Object',
          'Boolean|Array<String|Hash<Symbol,Point>|Array<String>>',
          'Array(len: 5)',
          'String(format: /woo/)',
          'String(#size)',
          'Integer(min: 1, max: 10)',
          'Array<String(min: 3)>',
          'Hash<Symbol,String(min: 3)>',
          'Array<String(min: 3)>(max: 10)',
          'Hash<Symbol, String>',
          'String(val: "This is a test.")'
        ]
    end

    context "has a class method .validate that" do
      setup do
        @invalid_strings =
          [ '',
            '|',
            '<',
            '>',
            'Stri,ng',
            'Stri:ng',
            'Stri/ng',
            'Stri ng',
            '|String',
            'String|',
            '<Array',
            '>Array',
            'Array<>',
            'String<',
            'String>',
            'Integer<<',
            'Array<Array<',
            'Array<Array<(String)>',
            'Array<(String>',
            'Array(len)',
            'Array(len: )',
            'Array(len: 5',
            'Array((len: 5))',
            'Array(len: 5, (len: 5)| len: 5)',
            'Array(len: 5, len)',
            'String(format: /)',
            'String(format: //)',
            'String(format: /a/th)',
            'Integer(mi,n: 5)',
            'Integer((min: 5)',
            'Hash< Symbol, Integer(max: 5)>'
          ]
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
          error = assert_raises(SyntaxError) { @Parser.validate(i) }
#          puts error.message
        end
      end
    end

    context "has a class method .parse that" do
      setup do
        @invalid_strings = ['String(len: 5, len: 5)']
      end

      should "return an array of TypeCheck::TypeElement for valid inputs" do
        @valid_inputs.each do |v|
          assert_equal TypeCheckParserTest.remove_white_space(v),
                       TypeCheckParserTest.reverse_parse(@Parser.parse(v))
        end
      end

      should "raise a SyntaxError for invalid strings" do
        @invalid_strings.each do |i|
          error = assert_raises(SyntaxError) { @Parser.parse(i) }
#          puts error.message
        end
      end
    end
  end

  def self.reverse_parse(array)
    array.reduce(nil) do |memo, a|
      memo = (memo.nil?) ? '' : memo + '|'
      memo += a.name
      memo += self.reverse_parse_child(a.child_type)
      memo += self.reverse_parse_constraints(a.constraints)
    end
  end

  def self.reverse_parse_child(child)
    return '' if child.nil?
    inner = child.reduce(nil) do |memo, c|
              memo = (memo.nil?) ? '' : memo + ','
              memo + self.reverse_parse(c)
            end
    '<' + inner + '>'
  end

  def self.reverse_parse_constraints(constraints)
    return '' if constraints.nil?
    inner = constraints.reduce(nil) do |memo, c|
              (memo.nil?) ? c.to_s : memo + ',' + c.to_s
            end
    '(' + inner + ')'
  end

  def self.remove_white_space(str)
    result = ''
    is_skip = false
    skips = [ '/', '"' ]
    closing_symbol = ''
    str.each_char do |c|
      if is_skip
        is_skip = false if c == closing_symbol
      else
        c = '' if c == ' '
        if skips.any? { |s| s == c }
          closing_symbol = c
          is_skip = true
        end
      end
      result += c
    end
    result
  end
end