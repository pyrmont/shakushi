require_relative 'cache'
require_relative 'parser'
require_relative 'type_element'

module Taipo
  module Check
    alias types binding

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
                raise SyntaxError, msg
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
          raise TypeError, msg
        end

        (is_match) ? memo : memo.push(k)
      end
    end
  end
end
