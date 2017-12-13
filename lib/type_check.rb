require_relative 'type_check/type_element'
require_relative 'type_check/parser'

module TypeCheck
  alias types binding

  def check(context, **checks)
    msg = "The first argument to this method must be of type Binding."
    raise TypeError, msg unless context.is_a? Binding

    checks.each do |k, v|
      arg = context.local_variable_get(k)
      classes = TypeCheck::Parser.parse v
      match = classes.reduce(false) do |memo, c|
        break memo if memo == true
        c.match? arg
      end
      msg = "The object '#{k}' is #{arg.class.name} but expected #{v}"
      raise TypeError, msg unless match
    end
  end
end