require_relative 'shakushi/xml'
require_relative 'shakushi/entry'
require_relative 'shakushi/feed_manager'
require_relative 'shakushi/page_manager'
require_relative 'shakushi/datastore'

module Shakushi
  ATOM_TAGS = { feed: 'feed', entry: 'entry', title: 'title', id: 'id',
                published: 'published', summary: 'content', link: 'link' }
  PODCAST_TAGS = { feed: 'channel', entry: 'item', title: 'title', id: 'guid',
                   published: 'pubDate', summary: 'description',
                   link: 'enclosure' }
  RSS_TAGS = { feed: 'channel', entry: 'item', title: 'title', id: 'guid',
               published: 'pubDate', summary: 'description', link: 'link' }
  FILE_SEP = '/'
  OUTPUT_DIRNAME = 'output'
  TEMPLATE_DIRNAME = 'templates'
  FEED_FILENAME = 'feed.xml'
  MAX_ITEMS = 20

  def self.generate_feed(params)
    fm = Shakushi::FeedManager.new(params[:target],
                                   type: params[:type],
                                   domain: params[:domain],
                                   dirname: params[:id])
    data = Shakushi::Datastore.new dirname: params[:id]

    filters = params[:filters]
    properties = params[:properties]
    function = params[:function]

    fm.filter_feed patterns: filters unless filters.nil?
    fm.change_properties replacements: properties unless properties.nil?
    fm.transform_entries function: function unless function.nil?
    fm.save_feed dirname: params[:id]

    data.save_entries fm.entries
  end

  def self.generate_page(params, title: '')
    pm = Shakushi::PageManager.new dirname: params[:id], page_title: title
    data = Shakushi::Datastore.new dirname: params[:id]

    pm.save_page entries: data.restore_entries
  end

  def self.generate_archive(params, title: '')
    pm = Shakushi::PageManager.new dirname: params[:id], page_title: title
    data = Shakushi::Datastore.new dirname: params[:id]

    pm.save_archive entries: data.restore_entries(limit: :none)
  end
end