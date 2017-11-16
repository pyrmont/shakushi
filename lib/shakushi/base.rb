require 'digest'
require 'open-uri'
require 'nokogiri'

module Shakushi
  class Base
    DATA_DIR = 'data'
    FEED_FILENAME = 'feed.xml'
    FILE_EXT = '.item'
    FILE_SEP = '/'
    MAX_ITEMS = 20
    ATOM_TAGS = { feed: 'feed', entry: 'entry', id: 'id',
                  published: 'published' }
    RSS_TAGS = { feed: 'channel', entry: 'item', id: 'guid',
                 published: 'pubDate' }

    def initialize(feed_type:,
                   feed_attributes:,
                   parent_url:,
                   content_dir:,
                   target_url:,
                   filters:,
                   match_all: false,
                   item_function: nil)
      @tag = setup_tag_names feed_type: feed_type
      @feed_attributes = feed_attributes
      @parent_url = parent_url
      @content_dir = content_dir
      @data_dir = setup_cache content_dir: @content_dir
      @feed = build_feed(url: target_url,
                         filters: filters,
                         match_all: match_all,
                         item_function: item_function)
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
      dirname = DATA_DIR + FILE_SEP + content_dir
      Dir.mkdir dirname unless File.directory? dirname
      dirname
    end

    def build_feed(url:, filters:, match_all:, item_function:)
      feed = filter(xml: Nokogiri::XML(open(url)),
                    filters: filters.map { |f|
                      Shakushi::Filter.new tag: f[:tag], pattern: f[:pattern]
                    },
                    match_all: match_all,
                    item_function: item_function)
      feed = modify_tags xml: feed
      feed = preserve_items xml: feed
      feed = restore_items xml: feed
    end

    def filter(xml:, filters:, match_all:, item_function:)
      xml.search(@tag[:entry])&.each do |item|
        if keep?(item, filters: filters, match_all: match_all)
          item_function.call item unless item_function == nil
        else
          item.unlink
        end
      end
      xml
    end

    def keep?(item, filters:, match_all:)
      if match_all
        filters.reduce(nil) do |memo, f|
          (memo == nil) ? f.keep?(item) : memo && f.keep?(item)
        end
      else
        filters.reduce(nil) do |memo, f|
          (memo == nil) ? f.keep?(item) : memo || f.keep?(item)
        end
      end
    end

    def modify_tags(xml:)
      link = @parent_url + FILE_SEP + @content_dir + FILE_SEP + FEED_FILENAME
      @feed_attributes[:link] = link unless @feed_attributes[:link]
      @feed_attributes.each do |tag, content|
        xml = if tag == :itunes
                modify_itunes_tags xml: xml, tags: content
              else
                modify_others_tags xml: xml, tag: tag, content: content
              end
      end
      xml
    end

    def modify_itunes_tags(xml:, tags:)
      tags.each do |partial, content|
        node = find_or_create_node xml: xml, tag: 'itunes:' + partial.to_s
        if partial == :image
          node['href'] = content
        else
          node.content = content
        end
      end
      xml
    end

    def modify_others_tags(xml:, tag:, content:)
      node = find_or_create_node xml: xml, tag: tag
      node.content = content
      xml
    end

    def find_or_create_node(xml:, tag:)
      node = if result = xml.at_css(tag.to_s)
               result
             else
               parent_node = xml.at_css @tag[:feed]
               parent_node.add_child Nokogiri::XML::Node.new(tag.to_s, xml)
             end
    end

    def preserve_items(xml:)
      xml.search(@tag[:entry])&.each do |item|
        date = DateTime.parse item.at_css(@tag[:published]).content
        time = date.to_time.to_i
        hash = Digest::MD5.hexdigest item.at_css(@tag[:id]).content
        dir_path = @data_dir + FILE_SEP + date.year.to_s
        file_path = dir_path + FILE_SEP + time.to_s + '-' + hash + FILE_EXT
        Dir.mkdir dir_path unless File.directory? dir_path
        File.open(file_path, 'w') { |file| file.write(item.to_xml) }
        item.unlink
      end
      xml
    end

    def restore_items(xml:)
      dirs = get_entries dir: @data_dir, pattern: /\A\d{4}\z/
      count = 0
      parent_node = xml.at_css @tag[:feed]
      dirs.each do |d|
        year_dir = @data_dir + FILE_SEP + d
        filenames = get_entries dir: year_dir, pattern: /#{FILE_EXT}\z/
        filenames.each do |f|
          parent_node.add_child File.read(year_dir + FILE_SEP + f)
          break if (count = count + 1) > MAX_ITEMS
        end
        break if count > MAX_ITEMS
      end
      xml
    end

    def get_entries(dir:, pattern:)
      Dir.entries(dir).select { |e| pattern === e }.sort.reverse
    end
  end
end