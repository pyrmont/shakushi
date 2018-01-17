require_relative 'cache'
require_relative 'exceptions'
require_relative 'parser'
require_relative 'type_element'

module Taipo
  
  # A dedicated namespace for methods meant to be included by the user
  #
  # @since 1.0.0
  module Check
    
    # Syntactic sugar to allow a user to write +check types,...+ and +review 
    #   types,...+
    #
    # @since 1.0.0
    alias types binding
    
    # Check whether the given arguments match the given type definition in the given context
    #
    # @param context [Binding] the context in which the arguments to be checked are defined
    # @param collect_invalids [Boolean] whether to raise an exception for, or collect, an argument that doesn't match its type definition
    # @param checks [Hash] the arguments to be checked written as <Symbol: String> pairs with the Symbol being the name of the argument and the String being its type definition
    #
    # @return [Array] the arguments which don't match (ie. an empty array if all arguments match)
    #
    # @since 1.0.0
    #
    # @example
    #   require 'taipo'
    #
    #   class A
    #     include Taipo::Check
    #
    #     def foo(str)
    #       check types, str: 'String'
    #       puts str
    #     end
    #     
    #     def bar(str)
    #       check types, str: 'Integer'
    #       puts str
    #     end
    #   end
    #
    #   a = A.new()
    #   a.foo('Hello world!')     # "Hello world!"
    #   a.bar('Goodbye world!')   # raise Taipo::TypeError
    def check(context, collect_invalids = false, **checks)
      msg = "The first argument to this method must be of type Binding."
      raise TypeError, msg unless context.is_a? Binding

      checks.reduce(Array.new) do |memo,(k,v)|
        arg = if k[0] == '@' && self.instance_variable_defined?(k)
                self.instance_variable_get k
              elsif k[0] != '@' && context.local_variable_defined?(k)
                context.local_variable_get k
              else
                msg = "Argument '#{k}' is not defined."
                raise Taipo::NameError, msg
              end

        types = if hit = Taipo::Cache[v]
                  hit
                else
                  Taipo::Cache[v] = Taipo::Parser.parse v
                end

        is_match = types.any? { |t| t.match? arg }

        unless collect_invalids || is_match
          if Taipo::instance_method? v
            msg = "Object '#{k}' does not respond to #{v}."
          elsif arg.is_a? Enumerable
            type_string = arg.class.name + Taipo.child_types_string(arg)
            msg = "Object '#{k}' is #{type_string} but expected #{v}."
          else
            msg = "Object '#{k}' is #{arg.class.name} but expected #{v}."
          end
          raise Taipo::TypeError, msg
        end

        (is_match) ? memo : memo.push(k)
      end
    end
  end
end
