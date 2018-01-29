require 'taipo'

module Shakushi
  class Filter
    include Taipo::Check

    def initialize(tag: nil, pattern: nil, tags_and_patterns: nil)
      check types, tag: 'String?', pattern: 'Regexp?',
        tags_and_patterns: 'Array?<Hash<Symbol,String|Regexp>>'

      if (tag.nil? || pattern.nil?) && tags_and_patterns.nil?
        # Can't have nil tag or pattern and nil tags_and_patterns
        raise ArgumentError
      elsif (!tag.nil? || !pattern.nil?) && !tags_and_patterns.nil?
        # Can't have non-nil tag or pattern and non-nil tags_and_patterns
        raise ArgumentError
      end
      
      @pairs = Array.new
      if tags_and_patterns
        tags_and_patterns.each do |tp|
          @pairs.push tp
        end
      else
        @pairs.push({ tag: tag, pattern: pattern })
      end
    end

    def filter(arg)
    end
  end
end
