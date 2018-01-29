require 'test_helper'
require 'shakushi'

class ShakushiFilterTest < Minitest::Test
  context "Shakushi::Filter" do
   
    context "has an #initialize method that" do
    
      should "create an instance when passed valid arguments" do
        filter = Shakushi::Filter.new tag: '<title>', pattern: /A-z+/
        assert_equal 'Shakushi::Filter', filter.class.name
      end

      should "create an instance when passed an array of tags and patterns" do
        filter = Shakushi::Filter.new tags_and_patterns: [{tag: 'title', pattern: /A-z+/}]
        assert_equal 'Shakushi::Filter', filter.class.name
      end

    end

  end
end
