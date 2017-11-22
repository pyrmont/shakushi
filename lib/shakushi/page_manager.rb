module Shakushi
  class PageManager
    OUTPUT_DIR = 'output'

    def initialize(content_dir)
      @output_dir = OUTPUT_DIR + FILE_SEP + content_dir
    end

    def generate_page(entries:)
      @entries = entries.map do |e|
                   entry = Hash.new
                   entry[:title] = e.xml.child(selector: 'title').content
                   entry[:url] = e.xml.child(selector: 'link').content
                   entry[:summary] = e.xml.child(selector: 'description').content
                   entry
                 end
      puts @entries.inspect
    end
  end
end