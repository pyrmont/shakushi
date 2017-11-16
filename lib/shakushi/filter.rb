module Shakushi
  class Filter
    def initialize(tag:, pattern:)
      @tag_name = tag
      @pattern = pattern
    end

    def keep?(item)
      item.search(@tag_name)&.reduce(false) do |memo, t|
        memo = true if @pattern === t.content
      end
    end
  end
end