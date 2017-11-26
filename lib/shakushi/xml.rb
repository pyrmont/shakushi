require 'open-uri'
require 'nokogiri'

module Shakushi
  module XML
    module Parser
      def self.parse(xml_or_url)
        xml = (url?(xml_or_url)) ? open(xml_or_url).read : xml_or_url
        doc = Nokogiri::XML xml, &:noblanks
        Shakushi::XML::Element.new doc.root
      end

      private

      def self.url?(input)
        /\Ahttps?/ === input # TODO: Find a better way to test.
      end
    end

    class Element
      attr_reader :name

#      def self.new(element)
#        return nil if val.nil?
#        super
#      end

      def initialize(element)
        @element = element
        @name = element.name
      end

      def [](key)
        @element[key]
      end

      def []=(key, value)
        @element[key] = value
      end

      def add_child(name:)
        doc = @element.document
        child = Shakushi::XML::Element.new Nokogiri::XML::Node.new(name, doc)
        @element.add_child child
      end

      def child(selector:)
        result = @element.at_css selector
        (result.nil?) ? nil : Shakushi::XML::Element.new(result)
      end

      def children(selector:)
        @element.search(selector).map do |child|
          Shakushi::XML::Element.new child
        end
      end

      def contains?(tag_name, pattern)
        @element.search(tag_name)&.reduce(false) do |memo, t|
          memo = true if pattern === t.content
        end
      end

      def content
        @element.content
      end

      def content=(value)
        @element.content = value
      end

      def remove
        @element.unlink
      end

      def to_s
        @element.to_xml indent: 4, :encoding => 'UTF-8'
      end
    end
  end
end