module TypeCheck
  class TypeElement
    class Constraint
      METHOD = '#'

      attr_accessor :name
      attr_reader :value

      def initialize(name: nil, value: nil)
        msg = 'Argument name was not a String.'
        raise TypeError, msg unless name.nil? || name.is_a?(String)
        msg = 'Argument name was an empty string.'
        raise ArgumentError, msg if name&.empty?

        @name = (name.nil?) ? Constraint::METHOD : name
        @value = value
      end

      def to_s
        name_string = (@name == Constraint::METHOD) ? '#' : @name + ': '
        value_string = case @name
                       when Constraint::METHOD
                         @value
                       when 'format'
                         @value.inspect
                       when 'len', 'max', 'min'
                         @value.to_s
                       else
                         @value
                       end
        name_string + value_string
      end

      def value=(v)
        case @name
        when Constraint::METHOD
          @value = v
        when 'format'
          msg = 'The value is not a regular expression.'
          raise SyntaxError, msg unless v[0] == '/' && v[-1] == '/'
          @value = Regexp.new v[1, v.length-2]
        when 'len', 'max', 'min'
          msg = 'The value is not an Integer.'
          raise SyntaxError, msg unless v == v.to_i.to_s
          @value = v.to_i
        end
      end

      def within?(arg)
        case @name
        when Constraint::METHOD
          arg.respond_to? @value
        when 'format'
          arg.is_a? String && arg =~ @value
        when 'len'
          arg.respond_to? 'size' && arg.size == @value
        when 'max'
          arg.respond_to? '<=' && arg <= @value
        when 'min'
          arg.respond_to? '>=' && arg >= @value
        end
      end
    end
  end
end