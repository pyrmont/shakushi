module Shakushi
  class DatastoreManager
    def initialize(content_dir)
      @datastore = Shakushi::Datastore.new content_dir
    end

    def restore_entries(limit: MAX_ITEMS)
      entries = @datastore.restore_entries limit: limit
    end

    def save_entries(entries)
      entries.each do |e|
        @datastore.save_entry e
      end
    end
  end

  require 'digest'

  class Datastore
    ATOM_EXT = '.entry'
    RSS_EXT = '.item'
    DATA_DIR = 'data'

    def initialize(content_dir)
      @ext = { atom: ATOM_EXT, rss: RSS_EXT }
      @data_dir = DATA_DIR + FILE_SEP + content_dir
      Dir.mkdir @data_dir unless File.directory? @data_dir
    end

    def filter_files(dir:, pattern:)
      Dir.entries(dir).select { |e| pattern === e }.sort.reverse
    end

    def list_files(limit:)
      dirs = filter_files dir: @data_dir, pattern: /\A\d{4}\z/
      files = dirs.reduce(Array.new) do |memo, d|
                break if memo.length > limit
                year_dir = @data_dir + FILE_SEP + d
                ext_pattern = /#{ATOM_EXT}|#{RSS_EXT}\z/
                filenames = filter_files dir: year_dir, pattern: ext_pattern
                memo + filenames.map { |f| year_dir + FILE_SEP + f }
              end
      (files.length > limit) ? files.slice(0, limit) : files
    end

    def restore_entries(limit:)
      filenames = list_files limit: limit
      entries = filenames.map { |f| restore_entry filename: f }
    end

    def restore_entry(filename:)
      type = case File.extname filename
             when ATOM_EXT then :atom
             when RSS_EXT then :rss
             end
      text = File.read filename
      entry = Shakushi::Entry.new type: type, text: text
    end

    def save_entry(entry)
      year = entry.date.year.to_s
      time = entry.unixtime.to_s
      hash = entry.crypto_hash
      dir_path = @data_dir + FILE_SEP + year
      file_path = dir_path + FILE_SEP + time + '-' + hash + @ext[entry.type]
      Dir.mkdir dir_path unless File.directory? dir_path
      File.open(file_path, 'w') { |file| file.write(entry.to_s) }
    end
  end
end