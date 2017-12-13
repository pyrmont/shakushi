require_relative 'type_element/constraint'

module TypeCheck
  class TypeElement
    attr_accessor :name
    attr_accessor :collection
    attr_accessor :constraints

    def initialize(name:, collection: nil, constraints: nil)
      msg = 'Argument name was not a String.'
      raise TypeError, msg unless name.is_a? String
      msg = 'Argument name was an empty string.'
      raise ArgumentError, msg if name.empty?
      msg = 'Argument collection was not an Array.'
      raise TypeError, msg unless (collection.nil? || collection.is_a?(Array))
      msg = 'Argument collection was empty.'
      raise ArgumentError, msg if collection&.empty?
      msg = 'Argument constraints was not an Array.'
      raise TypeError, msg unless (constraints.nil? || constraints.is_a?(Array))
      msg = 'Argument constraints was empty.'
      raise ArgumentError, msg if constraints&.empty?

      @name = name
      @collection = collection
      @constraints = constraints
    end

    def ==(comp)
      msg = 'Object to be compared must be of type TypeCheck::TypeElement.'
      raise TypeError, msg unless comp.is_a? TypeCheck::TypeElement

      @name == comp.name && @collection == comp.collection
    end

    def match?(arg)
      match_class?(arg) && match_children?(arg)
    end

    def match_class?(arg)
      if @name == 'Boolean'
        arg.is_a?(TrueClass) || arg.is_a?(FalseClass)
      else
        msg = "Class to match #{@name} is not defined"
        raise SyntaxError, msg unless Object.const_defined?(@name)
        arg.is_a? Object.const_get(@name)
      end
    end

    def match_children?(arg)
      if @collection.nil?
        true
      else
        arg.is_a?(Enumerable) && arg.reduce(false) do |memo, a|
          @collection.reduce(false) do |col_memo, c|
            break true if col_memo == true
            c.match? a
          end
        end
      end
    end
  end
end