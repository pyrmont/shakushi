module Shakushi
  class FeedManager

    def initialize(url, type:, domain:, dirname:)
      xml = Shakushi::XML::Parser.parse url
      @feed = Shakushi::FeedManager::Feed.new xml, type: type
      @feed_url = domain + '/' + dirname + '/' + FEED_FILENAME
    end

    def change_properties(replacements:)
      replacements[:link] = @feed_url
      replacements.each do |tag, value|
        if tag == :itunes
          change_itunes_tags tags: value
        else
          change_tag tag_name: tag.to_s, content: value
        end
      end
    end

    def change_itunes_tags(tags:)
      tags.each do |partial, content|
        element = @feed.property(name: 'itunes|' + partial.to_s)
        if partial == :image
          element['href'] = content
        elsif partial == :category
          element['text'] = content
        else
          element.content = content
        end
      end
    end

    def change_tag(tag_name:, content:)
      element = @feed.property(name: tag_name)
      element.content = content
    end

    def entries
      @feed.entries.map { |e| Shakushi::Entry.new type: @feed.type, xml: e }
    end

    def filter_feed(patterns:, match_all: false)
      filters = patterns.map do |f|
                  Shakushi::FeedManager::Filter.new(tag_name: f[:tag],
                                                    pattern: f[:pattern])
                end
      @feed.entries.each do |entry|
        keep = if match_all
          # TODO: Should be `reduce(false) ... memo && f.match?(entry)` etc
                 filters.reduce(nil) do |memo, f|
                   (memo == nil) ? f.match?(entry) : memo && f.match?(entry)
                 end
               else
                 filters.reduce(nil) do |memo, f|
                   (memo == nil) ? f.match?(entry) : memo || f.match?(entry)
                 end
               end
        entry.remove unless keep
      end
    end

    def output(output_format)
      case output_format
      when :text then @feed.to_s
      end
    end

    def save_feed(dirname:)
      dirpath = Shakushi.output_dir + FILE_SEP + dirname
      Dir.mkdir dirpath unless File.directory? dirpath
      filepath = dirpath + FILE_SEP + FEED_FILENAME
      File.open(filepath, 'w') { |file| file.write(@feed.to_s) }
    end

    def transform_entries(function:)
      @feed.entries.each do |entry|
        function.call entry
      end
    end
  end

  class FeedManager::Feed
    attr_reader :type

    def initialize(xml, type: :rss)
      @tag_name = case type
                  when :atom then ATOM_TAGS
                  when :podcast then PODCAST_TAGS
                  when :rss then RSS_TAGS
                  end
      @type = type
      @xml = xml
    end

    def entries
      entries = @xml.children(selector: @tag_name[:entry])
    end

    def properties
      feed_element = case @type
                     when :rss then @xml.child(selector: @tag_name[:feed])
                     when :podcast then @xml.child(selector: @tag_name[:feed])
                     when :atom then @xml
                     end
      properties = feed_element.children.select do |child|
                     if child.name != @tag_name[:entry]
                       Shakushi::XML::Element.new child
                     end
                   end
    end

    def property(name:)
      child = @xml.child(selector: name)
      property = (child) ? child : @xml.add_child(name: name)
    end

    def to_s
      @xml.to_s
    end
  end

  class FeedManager::Filter
    def initialize(tag_name:, pattern:)
      @tag_name = tag_name
      @pattern = pattern
    end

    def match?(element)
      element.contains? @tag_name, @pattern
    end
  end
end
