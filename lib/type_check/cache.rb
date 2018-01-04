module TypeCheck
  module Cache
    @@Cache = {}

    def self.[](v)
      @@Cache[v]
    end

    def self.[]=(k,v)
      @@Cache[k] = v
    end

    def self.reset()
      @@Cache = {}
    end
  end
end