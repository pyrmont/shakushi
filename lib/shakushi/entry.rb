module Shakushi
  class Entry
    attr_reader :type, :xml

    def initialize(type:, xml: nil, text: '')
      @type = type
      @xml = (xml.nil?) ? Shakushi::XML::Parser.parse(text) : xml
      @tag_name = case @type
                  when :atom then ATOM_TAGS
                  when :podcast then PODCAST_TAGS
                  when :rss then RSS_TAGS
                  end
    end

    def crypto_hash
      Digest::MD5.hexdigest @xml.child(selector: @tag_name[:id])&.content
    end

    def date
      DateTime.parse @xml.child(selector: @tag_name[:published])&.content
    end

    def link
      child = @xml.child selector: @tag_name[:link]
      if child.nil?
        ''
      elsif @type == :podcast
        child['url']
      else
        child.content
      end
    end

    def summary
      child = @xml.child selector: @tag_name[:summary]
      (child.nil?) ? '' : child.content
    end

    def title
      child = @xml.child selector: @tag_name[:title]
      (child.nil?) ? '' : child.content
    end

    def to_s
      @xml.to_s
    end

    def unixtime
      date.to_time.to_i
    end
  end
end