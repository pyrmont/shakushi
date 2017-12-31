require_relative 'type_check/type_element'
require_relative 'type_check/parser'

module TypeCheck
  alias types binding

  def check(context, **checks)
    msg = "The first argument to this method must be of type Binding."
    raise TypeError, msg unless context.is_a? Binding

    checks.each do |k,v|
      arg = context.local_variable_get k
      types = TypeCheck::Parser.parse v
      is_match = types.any? { |t| t.match? arg }
      msg = "The object '#{k}' is #{arg.class.name} but expected #{v}"
      raise TypeError, msg unless is_match
    end
  end
end