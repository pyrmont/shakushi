require_relative 'type_check/type_element'
require_relative 'type_check/parser'

module TypeCheck
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
      types = TypeCheck::Parser.parse v
      is_match = types.any? { |t| t.match? arg }
      unless collect_invalids
        msg = "Object '#{k}' is #{arg.class.name} but expected #{v}."
        raise TypeError, msg unless is_match
      end
      (is_match) ? memo : memo.push(k)
    end
  end
end