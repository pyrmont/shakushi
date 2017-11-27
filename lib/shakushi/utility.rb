module Shakushi
  module TypeCheck
    Boolean = 'Boolean'
    alias types binding

    def check(context, **checks)
      checks.each do |k, v|
        arg = context.local_variable_get(k)
        if v == Boolean
          error_message = "`#{k}` is type #{arg.class.name}, not a Boolean"
          raise TypeError, error_message unless arg == true || arg == false
        else
          error_message = "`#{k}` is type #{arg.class.name}, not type #{v}"
          raise TypeError, error_message unless arg.is_a? v
        end
      end
    end
  end
end