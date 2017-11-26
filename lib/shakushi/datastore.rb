module Shakushi
  class Datastore
    def initialize(datastore: nil, dirname: '')
      @datastore = if datastore.nil?
                     Shakushi::Datastore::Repository.new dirname
                   else
                     datastore
                   end
    end

    def restore_entries(limit: MAX_ITEMS)
      limit = (limit == :none) ? Float::INFINITY : limit
      entries = @datastore.restore_entries limit: limit
    end

    def save_entries(entries)
      entries.each do |e|
        @datastore.save_entry e
      end
    end
  end

  require 'digest'

  class Datastore::Repository
    ATOM_EXT = '.entry'
    RSS_EXT = '.item'
    PODCAST_EXT = '.pod'
    DATA_DIRNAME = 'data'

    def initialize(dirname)
      @ext = { atom: ATOM_EXT, podcast: PODCAST_EXT, rss: RSS_EXT }
      @data_dirpath = DATA_DIRNAME + FILE_SEP + dirname
      Dir.mkdir @data_dirpath unless File.directory? @data_dirpath
    end

    def filter_files(dirpath:, pattern:)
      Dir.entries(dirpath).select { |e| pattern === e }.sort.reverse
    end

    def list_filepaths(limit:)
      dirpaths = filter_files dirpath: @data_dirpath, pattern: /\A\d{4}\z/
      filepaths = dirpaths.reduce(Array.new) do |memo, d|
                  break if memo.length > limit
                  year_dirpath = @data_dirpath + FILE_SEP + d
                  ext_pattern = /#{ATOM_EXT}|#{PODCAST_EXT}|#{RSS_EXT}\z/
                  filenames = filter_files(dirpath: year_dirpath,
                                           pattern: ext_pattern)
                  memo + filenames.map { |f| year_dirpath + FILE_SEP + f }
              end
      (filepaths.length > limit) ? filepaths.slice(0, limit) : filepaths
    end

    def restore_entries(limit:)
      filepaths = list_filepaths limit: limit
      entries = filepaths.map { |f| restore_entry filepath: f }
    end

    def restore_entry(filepath:)
      type = case File.extname filepath
             when ATOM_EXT then :atom
             when PODCAST_EXT then :podcast
             when RSS_EXT then :rss
             end
      text = File.read filepath
      entry = Shakushi::Entry.new type: type, text: text
    end

    def save_entry(entry)
      year = entry.date.year.to_s
      time = entry.unixtime.to_s
      hash = entry.crypto_hash
      dirpath = @data_dirpath + FILE_SEP + year
      filepath = dirpath + FILE_SEP + time + '-' + hash + @ext[entry.type]
      Dir.mkdir dirpath unless File.directory? dirpath
      File.open(filepath, 'w') { |file| file.write(entry.to_s) }
    end
  end
end