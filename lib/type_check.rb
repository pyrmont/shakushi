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

  module Parser
    def self.parse(str)
      validate str

      content = ''
      stack = Array.new
      elements = Array.new
      stack.push elements

      str.each_char do |c|
        case c
        when '|'
          next if content.empty? # The previous character must have been '>'
          el = TypeCheck::TypeElement.new name: content
          content = ''
          elements = stack.pop
          elements.push el
          stack.push elements
        when '<'
          el = TypeCheck::TypeElement.new name: content
          content = ''
          stack.push el
          el_collection = Array.new
          stack.push el_collection
        when '>'
          if content.empty? # The previous character must have been '>'.
            parent_collection = stack.pop
          else
            el = TypeCheck::TypeElement.new name: content
            content = ''
            parent_collection = stack.pop
            parent_collection.push el
          end
          parent_el = stack.pop
          parent_el.collection = parent_collection
          elements = stack.pop
          elements.push parent_el
          stack.push elements
        when '('
          if content.empty? # The previous character must have been '>'.
            el = stack.pop
          else
            el = TypeCheck::TypeElement.new name: content
            content = ''
          end
          stack.push el
          cst_collection = Array.new
          stack.push cst_collection
        when '#'
          cst = TypeCheck::TypeElement::Constraint.new
          content = ''
          cst_collection = stack.pop
          cst_collection.push cst
          stack.push cst_collection
        when ':'
          cst = TypeCheck::TypeElement::Constraint.new name: content
          content = ''
          cst_collection = stack.pop
          cst_collection.push cst
          stack.push cst_collection
        when ','
          cst_collection = stack.pop
          cst = cst_collection.pop
          cst.value = content.strip
          content = ''
          cst_collection.push cst
          stack.push cst_collection
        when ')'
          cst_collection = stack.pop
          cst = cst_collection.pop
          cst.value = content.strip
          content = ''
          cst_collection.push cst
          el = stack.pop
          el.constraints = cst_collection
          elements = stack.pop
          elements.push el
          stack.push elements
        else
          content = content + c
        end
      end

      unless content.empty?
        el = TypeCheck::TypeElement.new name: content
        elements = stack.pop
        elements.push el
        stack.push elements
      end

      stack.pop
    end

    def self.validate(str)
      msg = "The argument to this method must be of type String."
      raise TypeError, msg unless str.is_a? String
      msg = "The string to be checked was empty."
      raise SyntaxError, msg if str.empty?

      status_array = [ :bar, :lab, :rab, :lpr, :rpr,:hsh, :cln, :sls, :cma,
                       :spc, :oth, :end ]
      counter_array = [ [ :angle, :paren, :const ],
                        { angle: '>', paren: ')', const: ":' or '#" } ]
      state = TypeCheck::Parser::SyntaxState.new(status_array, counter_array)

      i = 0
      chars = str.chars
      str_length = chars.size

      state.allow(:oth)

      while (i < str_length)
        msg = "The string '#{str}' has an error here: #{str[0, i+1]}"
        case chars[i]
        when '|' # bar
          conditions = [ state.allowed?(:bar) ]
          raise SyntaxError, msg unless conditions.all?
          state.prohibit_all except: [ :oth ]
        when '<' # lab
          conditions = [ state.allowed?(:lab) ]
          raise SyntaxError, msg unless conditions.all?
          state.prohibit_all except: [ :oth ]
          state.increment(:angle)
        when '>' # rab
          conditions = [ state.allowed?(:rab), state.gtz?(:angle) ]
          raise SyntaxError, msg unless conditions.all?
          state.prohibit_all except: [ :bar, :rab, :lpr, :end ]
          state.decrement(:angle)
        when '(' # lpr
          conditions = [ state.allowed?(:lpr) ]
          raise SyntaxError, msg unless conditions.all?
          state.prohibit_all except: [ :hsh, :oth ]
          state.increment(:paren)
          state.increment(:const)
        when ')' # rpr
          conditions = [ state.allowed?(:rpr), state.gtz?(:paren) ]
          raise SyntaxError, msg unless conditions.all?
          state.prohibit_all except: [ :bar, :end ]
          state.decrement(:paren)
        when '#' # hsh
          conditions = [ state.allowed?(:hsh) ]
          raise SyntaxError, msg unless conditions.all?
          state.prohibit_all except: [ :oth ]
          state.decrement(:const)
        when ':' # cln
          conditions = [ state.allowed?(:cln) ]
          raise SyntaxError, msg unless conditions.all?
          state.prohibit_all except: [ :spc ]
          state.decrement(:const)
        when '/' #sls
          conditions = [ state.allowed?(:sls) ]
          raise SyntaxError, msg unless conditions.all?
          i = TypeCheck::Parser.validate_regex(str, start: i+1)
          state.prohibit_all except: [ :rpr, :cma ]
        when ',' # cma
          conditions = [ state.allowed?(:cma) ]
          raise SyntaxError, msg unless conditions.all?
          state.prohibit_all except: [ :spc ]
          state.increment(:const)
        when ' ' # spc
          conditions = [ state.allowed?(:spc) ]
          raise SyntaxError, msg unless conditions.all?
          state.prohibit_all except: [ :sls, :oth ]
        else # oth
          conditions = [ state.allowed?(:oth) ]
          raise SyntaxError, msg unless conditions.all?
          state.allow_all except: [ :hsh, :spc ]
        end
        i += 1
      end
      msg_end = "The string '#{str}' ends with an illegal character."
      raise SyntaxError, msg_end unless state.allowed?(:end)

      missing = state.unbalanced
      msg_bal = "The string '#{str}' is missing a '#{missing.first}'."
      raise SyntaxError, msg_bal unless missing.size == 0
    end

    def self.validate_regex(str, start: 0)
      status_array = [ :bsl, :sls, :opt, :oth ]
      counter_array = [ [ :backslash ], { backslash: '/' } ]

      state = SyntaxState.new(status_array, counter_array)
      state.prohibit_all except: [ :bsl, :oth ]
      finish = start

      str[start, str.length-start].each_char.with_index(start) do |c, i|
        if state.gtz?(:backslash) # The preceding character was a backslash.
          state.decrement(:backslash)
          next # Any character after a backslash is allowed.
        end

        msg = "The string '#{str}' has an error here: #{str[0, i+1]}"

        case c
        when 'i', 'o', 'x', 'm', 'u', 'e', 's', 'n'
          next # We're either in the regex or in the options that follow.
        when '/'
          raise SyntaxError, msg unless state.allowed?(:sls)
          state.prohibit_all except: [ :opt ]
        when '\\'
          raise SyntaxError, msg unless state.allowed?(:bsl)
          state.increment(:backslash)
        when ',', ')'
          finish = i
          break unless state.allowed?(:oth) # The regex has ended.
        else
          raise SyntaxError, msg unless state.allowed?(:oth)
          state.allow_all
        end
      end

      msg = "The string '#{str}' is missing a '/'."
      raise SyntaxError, msg if finish == start

      finish - 1
    end

    class SyntaxState
      def initialize(state_names, counter_names_and_closers = nil)
        @status = Hash[state_names.map { |s| [s, :prohibited] }]
        if counter_names_and_closers.nil?
          @counter = Array.new
          @closers = Array.new
        else
          @counter = Hash[counter_names_and_closers[0].map { |c| [c, 0] }]
          @closers = counter_names_and_closers[1]
        end
      end

      def allow(key)
        @status[key] = :allowed
      end

      def allow_all(except: [])
        set_all :allowed, except: { exceptions: except, status: :prohibited }
      end

      def allowed?(status)
        @status[status] == :allowed
      end

      def count(key)
        @counter[key]
      end

      def decrement(key)
        @counter[key] -= 1
      end

      def increment(key)
        @counter[key] += 1
      end

      def gtz?(key)
        @counter[key] > 0
      end

      def ltz?(key)
        @counter[key] < 0
      end

      def prohibit(key)
        @status[key] = :prohibited
      end

      def prohibit_all(except: [])
        set_all :prohibited, except: { exceptions: except, status: :allowed }
      end

      def prohibited?(status)
        @status[status] == :prohibited
      end

      def set_all(status, except: {})
        @status.transform_values! { |v| v = status }
        except[:exceptions].each { |k| @status[k] = except[:status] }
      end

      def unbalanced()
        @counter.reduce(Array.new) do |memo, c|
          (c[1] == 0) ? memo : memo.push(@closers[c[0]])
        end
      end
    end
  end

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