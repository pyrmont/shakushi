module Shakushi
  class PageManager

    def initialize(dirname:, page_title:)
      @output_dirpath = OUTPUT_DIRNAME + FILE_SEP + dirname
      Dir.mkdir @output_dirpath unless File.directory? @output_dirpath
      @page_title = page_title
    end

    def save_archive(entries:)
      entries_by_year = Hash.new
      entries.each do |e|
        year = e.date.year
        entries_by_year[year] = Array.new unless entries_by_year.key? year
        entries_by_year[year].push e
      end

      years = entries_by_year.keys.map { |k| k.to_s }
      pages = entries_by_year.map do |y, e|
        Shakushi::PageManager::Page.new(template: :archive,
                                        filename: 'archive-' + y.to_s + '.html',
                                        page_title: @page_title,
                                        year: y.to_s,
                                        years: years,
                                        entries: e)
      end

      pages.each do |p|
        filepath = @output_dirpath + FILE_SEP + p.filename
        File.open(filepath, 'w') { |file| file.write(p.to_s) }
      end

      archive_filename = 'archive-' + years.max + '.html'
      redirect = Shakushi::PageManager::Page.new(template: :redirect,
                                                 filename: 'archive.html',
                                                 redirect: archive_filename)
      filepath = @output_dirpath + FILE_SEP + redirect.filename
      File.open(filepath, 'w') { |file| file.write(redirect.to_s) }
    end

    def save_page(entries:)
      page = Shakushi::PageManager::Page.new(template: :single,
                                             filename: 'index.html',
                                             page_title: @page_title,
                                             entries: entries)
      filepath = @output_dirpath + FILE_SEP + page.filename
      File.open(filepath, 'w') { |file| file.write(page.to_s) }
    end

    require 'erb'

    class PageManager::Page
      attr_reader :filename

      def initialize(template:, filename:, **options)
        @template = ERB.new File.read(TEMPLATE_DIRNAME +
                                      FILE_SEP +
                                      template.to_s +
                                      '.html.erb')
        @filename = filename

        case template
        when :archive
          @page_title = options[:page_title]
          @page_year = options[:year]
          @years = options[:years]
          @entries = options[:entries]
        when :redirect
          @redirect = options[:redirect]
        when :single
          @page_title = options[:page_title]
          @entries = options[:entries]
        end
      end

      def to_s
        @template.result(binding)
      end
    end
  end
end
