require 'open-uri'
require 'nokogiri'

module Shakushi
  class Base
    def initialize(feed_attributes:, parent_url:, content_dir:, target_url:, filters:, match_all: false)
      @feed_attributes = feed_attributes
      @parent_url = parent_url
      @content_dir = content_dir
      @cache_dir = setup_cache content_dir: @content_dir
      @feed = build_feed url: target_url, filters: filters, match_all: match_all
    end

    def output_rss
      @feed.to_xml
    end

    private

    def setup_cache(content_dir:)
      dirname = 'cache' + '/' + content_dir
      Dir.mkdir dirname unless File.directory? dirname
      dirname
    end

    def build_feed(url:, filters:, match_all:)
      feed = filter(
        xml: Nokogiri::XML(open(url)),
        filters: filters.map { |f|
          Shakushi::Filter.new(tag: f[:tag], pattern: f[:pattern])
        },
        match_all: match_all
      )
      feed = modify_tags xml: feed
      feed = preserve_items xml: feed
      feed = restore_items xml: feed
      feed
    end

    def filter(xml:, filters:, match_all:)
      xml.search('.//item')&.each do |item|
        if match_all
          keep_it = filters.reduce(nil) do |memo, f|
            (memo == nil) ? f.keep?(item) : memo && f.keep?(item)
          end
        else
          keep_it = filters.reduce(nil) do |memo, f|
            (memo == nil) ? f.keep?(item) : memo || f.keep?(item)
          end
        end
        item.unlink unless keep_it
      end
      xml
    end

    def modify_tags(xml:)
      @feed_attributes[:link] &&= @parent_url + '/' + @content_dir + '/feed.rss'
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

    def find_or_create_node(xml:, tag:, parent_tag: 'channel')
      if result = xml.at_xpath('//' + tag.to_s)
        node = result
      else
        parent_node = xml.at_xpath('//' + parent_tag)
        node = parent_node.add_child(Nokogiri::XML::Node.new tag.to_s, xml)
      end
    end

    def preserve_items(xml:)
      xml.search('.//item').each do |item|
        date = DateTime.parse item.at_xpath('.//pubDate').content
        filename = @cache_dir + '/' + date.to_time.to_i.to_s + '.item'
        File.open(filename, 'w') { |file| file.write(item.to_xml) }
        item.unlink
      end
      xml
    end

    def restore_items(xml:)
      parent_node = xml.at_xpath('//channel')
      filenames = Dir.entries(@cache_dir)
        .select { |fn| /\.item$/ === fn }
        .sort_by { |fn| fn }
      filenames.each do |fn|
        fragment_xml = File.read @cache_dir + '/' + fn
        parent_node.add_child fragment_xml
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
      item.search('.//' + @tag_name)&.reduce(false) do |memo, t|
        memo = true if @pattern === t.content
      end
    end
  end
end