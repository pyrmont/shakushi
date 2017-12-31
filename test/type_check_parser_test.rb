require 'yaml'
require 'test_helper'
require 'type_check'

class TypeCheckParserTest < Minitest::Test
  context "TypeCheck:Parser" do
    setup do
      @Parser = TypeCheck::Parser
      @valid_inputs = YAML.load_file 'test/data/valid_type_strings.yml'
    end

    context "has a class method .validate that" do
      setup do
        @invalid_strings = YAML.load_file 'test/data/invalid_type_strings.yml'
        @invalid_nonstrings = [ nil, Object.new, Array.new ]
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
          # error = assert_raises(SyntaxError) { @Parser.validate(i) }
          # puts error.message
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
          assert_raises(SyntaxError) { @Parser.parse(i) }
          # error = assert_raises(SyntaxError) { @Parser.parse(i) }
          # puts error.message
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