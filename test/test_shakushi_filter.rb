require 'test_helper'
require 'shakushi'

class ShakushiFilterTest < Minitest::Test
  context "Shakushi::Filter" do
   
    context "has an #initialize method that" do
    
      should "create an instance when passed valid arguments" do
        filter = Shakushi::Filter.new tag: 'title', pattern: /A-z+/
        assert_equal 'Shakushi::Filter', filter.class.name
      end

      should "create an instance when passed an array of tags and patterns" do
        filter = Shakushi::Filter.new tags_and_patterns: [ { tag: 'title', 
                                                             pattern: /A-z+/ } ]
        assert_equal 'Shakushi::Filter', filter.class.name
      end

      should "raise a Taipo::TypeError when arguments are the wrong type" do
        valid = { t: 'foo', p: 'foo', tp: [ { tag: 'foo', pattern: 'foo' } ] }
        invalid = { t: 1, p: Object.new, tp: { a: { t: 'foo', p: 'foo' } } }
        assert_raises(Taipo::TypeError) do
          Shakushi::Filter.new(tag: invalid[:t], pattern: valid[:p])
        end
        assert_raises(Taipo::TypeError) do
          Shakushi::Filter.new(tag: valid[:t], pattern: invalid[:p])
        end
        assert_raises(Taipo::TypeError) do
          Shakushi::Filter.new(tags_and_patterns: invalid[:tp])
        end
      end

      should "raise an ArgumentError when arguments are missing" do
        valid = { t: 'foo', p: 'foo', tp: [ { tag: 'foo', pattern: 'foo' } ] }
        invalid = { t: 1, p: Object.new, tp: { a: { t: 'foo', p: 'foo' } } }
        assert_raises(ArgumentError) do
          Shakushi::Filter.new
        end
        assert_raises(ArgumentError) do
          Shakushi::Filter.new(tag: nil, pattern: valid[:p])
        end
        assert_raises(ArgumentError) do
          Shakushi::Filter.new(tag: valid[:t], pattern: nil)
        end
        assert_raises(ArgumentError) do
          Shakushi::Filter.new(tag: valid[:t], pattern: valid[:p], 
                               tags_and_patterns: valid[:tp])
        end
      end
    end

  end
end
