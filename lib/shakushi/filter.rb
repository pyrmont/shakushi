require 'taipo'

module Shakushi

  # A filter
  #
  # A filter holds one or more patterns with each pattern associated with a
  # tag.
  #
  # If multiple patterns are held by the filter, {Shakushi::Filter#filter}
  # will filter out elements which do not match all of the patterns. For
  # situations in which only one of the patterns need to match, instead create
  # a {Shakushi::Filters} object with each pattern placed in a different
  # filter.
  #
  # @since 1.0.0
  # @api private
  class Filter
    include Taipo::Check

    # Initialize a filter
    #
    # This creates a filter in either one of two ways. The first way is the
    # simple provision of a tag and a pattern. The second way is as an array of
    # tags and patterns. {Shakushi::Filter#filter} will require all tags and
    # patterns to match.
    #
    # @param tag [String] the name of the tag
    # @param pattern [String|Regexp] the string or regular expression to match
    # @param tags_and_patterns [Array<Hash<Symbol,String|Regexp> a collection
    #   of tags and patterns
    #
    # @since 1.0.0
    # @api private
    def initialize(tag: nil, pattern: nil, tags_and_patterns: nil)
      check types, tag: 'String?', pattern: 'String?|Regexp?',
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

    # Return an item if it passes through the filter
    #
    # This method will filter out items that do not match all of the components
    # of the filter.
    #
    # @since 1.0.0
    # @api private
    def filter(arg)
      check types, arg: 'Shakushi::Feed::Entry'

    end
  end
end
