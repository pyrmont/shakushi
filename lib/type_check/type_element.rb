require_relative 'type_element/child_type'
require_relative 'type_element/constraint'

module TypeCheck
  class TypeElement
    attr_accessor :name
    attr_accessor :child_type
    attr_reader :constraints

    def initialize(name:, child_type: nil, constraints: nil)
      msg = 'Argument name was not a String.'
      raise TypeError, msg unless name.is_a? String
      msg = 'Argument name was an empty string.'
      raise ArgumentError, msg if name.empty?
      msg = 'Argument child_type was not TypeCheck::TypeElement::ChildType.'
      raise TypeError, msg unless (
                             child_type.nil? ||
                             child_type.is_a?(TypeCheck::TypeElement::ChildType)
                           )
      msg = 'Argument child_type was empty.'
      raise ArgumentError, msg if child_type&.empty?
      msg = 'Argument constraints was not an Array.'
      raise TypeError, msg unless (constraints.nil? || constraints.is_a?(Array))
      msg = 'Argument constraints was empty.'
      raise ArgumentError, msg if constraints&.empty?

      @name = name
      @child_type = child_type
      @constraints = constraints
    end

    def ==(comp)
      msg = 'Object to be compared must be of type TypeCheck::TypeElement.'
      raise TypeError, msg unless comp.is_a? TypeCheck::TypeElement

      @name == comp.name && @child_type == comp.child_type
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
      match_class?(arg) && match_constraints?(arg) && match_child_type?(arg)
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

    def match_child_type?(arg)
      self_childless = @child_type.nil?
      arg_childless = !arg.is_a?(Enumerable) || arg.count == 0
      return true if self_childless && arg_childless
      return false if self_childless && !arg_childless
      return false if !self_childless && arg_childless

      arg.all? do |a|
        if a.is_a?(Array) # The elements of this collection have components
          a.each.with_index.reduce(nil) do |memo,(component,index)|
            result = @child_type[index].any? { |c| c.match? component }
            (memo.nil?) ? result : memo && result
          end
        else # The elements of this collection have no components
          @child_type.first.any? { |c| c.match? a }
        end
      end
    end

    def match_constraints?(arg)
      return true if @constraints.nil?

      @constraints.all? do |c|
        c.constrain?(arg)
      end
    end
  end
end