require_relative 'shakushi/xml'
require_relative 'shakushi/entry'
require_relative 'shakushi/feed_manager'
require_relative 'shakushi/datastore_manager'
require_relative 'shakushi/page_manager'

module Shakushi
  ATOM_TAGS = { feed: 'feed', entry: 'entry', id: 'id',
                published: 'published' }
  RSS_TAGS = { feed: 'channel', entry: 'item', id: 'guid',
               published: 'pubDate' }
  FILE_SEP = '/'
  OUTPUT_DIR = 'output'
  MAX_ITEMS = 20
end