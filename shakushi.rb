require 'open-uri'
require 'nokogiri'

module Shakushi
  class Base
    def initialize(feed_attributes:, parent_url:, content_dir:, target_url:, filters:, match_all: false)
      @feed_attributes = feed_attributes
      @parent_url = parent_url
      @content_dir = content_dir
      @feed = modify(
        xml: filter(
          xml: Nokogiri::XML(open(target_url)),
          filters: filters.map { |f|
            Shakushi::Filter.new(tag: f[:tag], pattern: f[:pattern])
          },
          match_all: match_all
        )
      )
    end

    def output_rss
      @feed.to_xml
    end

    private

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

    def modify(xml:)
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