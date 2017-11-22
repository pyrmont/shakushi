module Shakushi
  class Entry
    attr_reader :type, :xml

    def initialize(type:, xml: nil, text: '')
      @type = type
      @xml = (xml.nil?) ? Shakushi::XML::Parser.parse(text) : xml
      @tag_name = case @type
                  when :atom then ATOM_TAGS
                  when :rss then RSS_TAGS
                  end
    end

    def crypto_hash
      Digest::MD5.hexdigest @xml.child(selector: @tag_name[:id]).content
    end

    def date
      DateTime.parse @xml.child(selector: @tag_name[:published]).content
    end

    def to_s
      @xml.to_s
    end

    def unixtime
      date.to_time.to_i
    end
  end
end