require_relative 'type_element/constraint'

module TypeCheck
  class TypeElement
    attr_accessor :name
    attr_accessor :children
    attr_reader :constraints

    def initialize(name:, children: nil, constraints: nil)
      msg = 'Argument name was not a String.'
      raise TypeError, msg unless name.is_a? String
      msg = 'Argument name was an empty string.'
      raise ArgumentError, msg if name.empty?
      msg = 'Argument children was not an Array.'
      raise TypeError, msg unless (children.nil? || children.is_a?(Array))
      msg = 'Argument children was empty.'
      raise ArgumentError, msg if children&.empty?
      msg = 'Argument constraints was not an Array.'
      raise TypeError, msg unless (constraints.nil? || constraints.is_a?(Array))
      msg = 'Argument constraints was empty.'
      raise ArgumentError, msg if constraints&.empty?

      @name = name
      @children = children
      @constraints = constraints
    end

    def ==(comp)
      msg = 'Object to be compared must be of type TypeCheck::TypeElement.'
      raise TypeError, msg unless comp.is_a? TypeCheck::TypeElement

      @name == comp.name && @children == comp.children
    end

    def constraints=(csts)
      msg = 'Argument csts was not an Array.'
      raise TypeError, msg unless csts.is_a? Array

      names = Hash.new
      csts.each do |c|
        msg = 'Contraints must have unique names.'
        raise SyntaxError, msg if names.key?(c.name)
        if c.name == TypeCheck::TypeElement::Constraint::METHOD
          names['#' + c.value] = true
        else
          names[c.name] = true
        end
      end
      @constraints = csts
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
      self_childless = @children.nil?
      arg_childless = !arg.is_a?(Enumerable) || arg.count == 0
      return true if self_childless && arg_childless
      return false if self_childless && !arg_childless
      return false if !self_childless && arg_childless

      arg.all? do |a|
        @children.any? do |c|
          c.match? a
        end
      end
    end
  end
end