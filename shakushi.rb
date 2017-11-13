require 'net/http'
require 'uri'
require 'feedjira'

module Shakushi
  class Base
    attr_reader :title
    attr_reader :description
    attr_reader :parent_url
    attr_reader :local_dir
    attr_reader :filtered_feed

    def initialize(title:, description:, parent_url:, local_dir:, target_url:, filters:, match_all:)
      @title = title
      @description = description
      @parent_url = parent_url
      @local_dir = local_dir
      @filtered_feed = filter(
        input: Feedjira::Feed.parse(Net::HTTP.get(URI.parse(target_url))),
        filters: filters.map { |f|
          Shakushi::Filter.new(attribute: f[:attribute], pattern: f[:pattern])
        },
        match_all: match_all
      )
    end

    private

    def filter(input:, filters:, match_all:)
      output = input
      output.entries = output.entries.select do |entry|
        if match_all
          filters.reduce(nil) do |memo, f|
            (memo == nil) ? f.keep?(entry) : memo && f.keep?(entry)
          end
        else
          filters.reduce(nil) do |memo, f|
            (memo == nil) ? f.keep?(entry) : memo || f.keep?(entry)
          end
        end
      end
      output
    end
  end

  class Filter
    attr_reader :attribute
    attr_reader :pattern

    def initialize(attribute:, pattern:)
      @attribute = attribute
      @pattern = pattern
    end

    def keep?(entry)
      value = entry.public_send @attribute
      @pattern === value
    end
  end
end

get_lowe = Shakushi::Base.new(
  title: 'Get Lowe',
  description: "Zach Lowe's ESPN columns.",
  parent_url: 'http://filtrates.inqk.net/',
  local_dir: 'get-lowe',
  target_url: 'http://www.espn.com/espn/rss/nba/news',
  filters: [
    { attribute: 'title', pattern: /^Lowe:/ }
  ],
  match_all: false
)

puts get_lowe.filtered_feed.inspect