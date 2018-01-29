require 'json'
require 'taipo'
require 'shakushi/feed'
require 'shakushi/filter'
require 'shakushi/transform'

module Shakushi
  class Configuration
    include Taipo::Check

    attr_reader :id
    attr_reader :feed
    attr_reader :output_host
    attr_reader :new_attrs
    attr_reader :filters
    attr_reader :transforms

    def initialize(filepath)
      check types, filepath: 'String'
      params = JSON.parse(file.read(open(filepath)))
      @id = params["id"].to_i
      @feed = Shakushi::Feed.new params["url"], params["format"].to_sym
      @output_host = params["output_host"]
      @new_attrs = params["new_attrs"]
      @filters = Shakushi::Filters.new params["filters"]
      @transforms = Shakushi::Transforms.parse params["transforms"]
    end
  end
end
