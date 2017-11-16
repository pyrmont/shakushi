require 'digest'
require 'open-uri'
require 'nokogiri'

module Shakushi
  class Base
    FEED_FILENAME = 'feed.xml'
    FILE_EXT = '.item'
    FILE_SEP = '/'
    MAX_ITEMS = 20
    ATOM_TAGS = { feed: 'feed', entry: 'entry', id: 'id', published: 'published' }
    RSS_TAGS = { feed: 'channel', entry: 'item', id: 'guid', published: 'pubDate' }

    def initialize(feed_type:, feed_attributes:, parent_url:, content_dir:, target_url:, filters:, match_all: false, item_function:)
      @t = setup_tag_names feed_type: feed_type
      @feed_attributes = feed_attributes
      @parent_url = parent_url
      @content_dir = content_dir
      @data_dir = setup_cache content_dir: @content_dir
      @feed = build_feed(
        url: target_url,
        filters: filters,
        match_all: match_all,
        item_function: item_function
      )
    end

    def output_rss
      @feed.to_xml
    end

    private

    def setup_tag_names(feed_type:)
      tag_names = case feed_type.to_sym
        when :atom then ATOM_TAGS
        when :rss then RSS_TAGS
      end
    end

    def setup_cache(content_dir:)
      dirname = 'data' + FILE_SEP + content_dir
      Dir.mkdir dirname unless File.directory? dirname
      dirname
    end

    def build_feed(url:, filters:, match_all:, item_function:)
      feed = filter(
        xml: Nokogiri::XML(open(url)),
        filters: filters.map { |f|
          Shakushi::Filter.new(tag: f[:tag], pattern: f[:pattern])
        },
        match_all: match_all,
        item_function: item_function
      )
      feed = modify_tags xml: feed
      feed = preserve_items xml: feed
      feed = restore_items xml: feed
    end

    def filter(xml:, filters:, match_all:, item_function:)
      xml.search(@t[:entry])&.each do |item|
        if match_all
          keep_it = filters.reduce(nil) do |memo, f|
            (memo == nil) ? f.keep?(item) : memo && f.keep?(item)
          end
        else
          keep_it = filters.reduce(nil) do |memo, f|
            (memo == nil) ? f.keep?(item) : memo || f.keep?(item)
          end
        end

        if keep_it
          item_function.call item
        else
          item.unlink
        end
      end
      xml
    end

    def modify_tags(xml:)
      @feed_attributes[:link] &&= @parent_url + FILE_SEP + @content_dir + FILE_SEP + FEED_FILENAME
      @feed_attributes.each do |tag, content|
        if tag == :itunes
          modify_itunes_tags(xml: xml, tags: content)
        else
          modify_others_tags(xml: xml, tag: tag, content: content)
        end
      end
      xml
    end

    def modify_itunes_tags(xml:, tags:)
      tags.each do |partial, content|
        node = find_or_create_node(xml: xml, tag: 'itunes:' + partial.to_s)
        if partial == :image
          node['href'] = content
        else
          node.content = content
        end
      end
    end

    def modify_others_tags(xml:, tag:, content:)
      node = find_or_create_node(xml: xml, tag: tag)
      node.content = content
    end

    def find_or_create_node(xml:, tag:, parent_tag: nil)
      parent_tag = @t[:feed] if parent_tag == nil
      if result = xml.at_css(tag.to_s)
        node = result
      else
        parent_node = xml.at_css(parent_tag)
        node = parent_node.add_child(Nokogiri::XML::Node.new tag.to_s, xml)
      end
    end

    def preserve_items(xml:)
      xml.search(@t[:entry]).each do |item|
        date = DateTime.parse item.at_css(@t[:published]).content
        time = date.to_time.to_i
        hash = Digest::MD5.hexdigest item.at_css(@t[:id]).content
        path = @data_dir + FILE_SEP + date.year.to_s
        Dir.mkdir path unless File.directory? path
        filepath = path + FILE_SEP + time.to_s + '-' + hash + FILE_EXT
        File.open(filepath, 'w') { |file| file.write(item.to_xml) }
        item.unlink
      end
      xml
    end

    def restore_items(xml:)
      parent_node = xml.at_css(@t[:feed])

      dirs = Dir.entries(@data_dir)
      .select { |fn| /^\d{4}$/ === fn }
      .sort
      .reverse

      count = 0
      dirs.each do |d|
        year_dir = @data_dir + FILE_SEP + d
        Dir.entries(year_dir)
        .select { |fn| /#{FILE_EXT}$/ === fn }
        .sort
        .reverse
        .each do |fn|
          fragment_xml = File.read year_dir + FILE_SEP + fn
          parent_node.add_child fragment_xml
          break if (count = count + 1) > MAX_ITEMS
        end
        break if count > MAX_ITEMS
      end

      xml
    end
  end

  class Filter
    def initialize(tag:, pattern:)
      @tag_name = tag
      @pattern = pattern
    end

    def keep?(item)
      item.search(@tag_name)&.reduce(false) do |memo, t|
        memo = true if @pattern === t.content
      end
    end
  end
end