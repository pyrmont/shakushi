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

      counterpart = { lab: '>',
                      lpr: ')',
                      constraint: ': or #' }

      state = TypeCheck::Parser::SyntaxState.new(:bar, :lab, :rab, :lpr, :rpr,
                                                 :hsh, :cln, :cma, :spc, :oth,
                                                 :end)
      state.allow(:oth)

      count = { lab: 0, lpr: 0, hsh: 0, constraint: 0 }

      i = 0
      chars = str.chars
      str_length = chars.size

      while (i < str_length)
        msg = "The string '#{str}' has an error here: #{str[0, i+1]}"
        case chars[i]
        when '|' # bar
          conditions = [ state.allow?(:bar) ]
          raise SyntaxError, msg unless conditions.all?
          state.prohibit_all except: [ :oth ]
        when '<' # lab
          conditions = [ state.allow?(:lab) ]
          raise SyntaxError, msg unless conditions.all?
          state.prohibit_all except: [ :oth ]
          count[:lab] = count[:lab] + 1
        when '>' # rab
          conditions = [ state.allow?(:rab), count[:lab] > 0 ]
          raise SyntaxError, msg unless conditions.all?
          state.prohibit_all except: [ :bar, :rab, :lpr, :end ]
          count[:lab] = count[:lab] - 1
        when '(' # lpr
          conditions = [ state.allow?(:lpr) || count[:hsh] == 1 ]
          raise SyntaxError, msg unless conditions.all?
          state.prohibit_all except: [ :hsh, :oth ]
          count[:lpr] = count[:lpr] + 1
          count[:constraint] = count[:constraint] + 1
        when ')' # rpr
          conditions = [ state.allow?(:rpr), count[:lpr] > 0 ]
          raise SyntaxError, msg unless conditions.all?
          state.prohibit_all except: [ :bar, :end ]
          count[:lpr] = count[:lpr] - 1
        when '#' # hsh
          conditions = [ state.allow?(:hsh) ]
          raise SyntaxError, msg unless conditions.all?
          state.prohibit_all except: [ :oth ]
          count[:constraint] = count[:constraint] - 1
          count[:hsh] = count[:hsh] + 1
        when ':' # cln
          conditions = [ state.allow?(:cln) ]
          raise SyntaxError, msg unless conditions.all?
          state.prohibit_all except: [ :spc ]
          count[:constraint] = count[:constraint] - 1
        when ',' # cma
          conditions = [ state.allow?(:cma) ]
          raise SyntaxError, msg unless conditions.all?
          state.prohibit_all except: [ :spc ]
          count[:constraint] = count[:constraint] + 1
        when ' ' # spc
          conditions = [ state.allow?(:spc) ]
          raise SyntaxError, msg unless conditions.all?
          state.prohibit_all except: [ :oth ]
        else # oth
          conditions = [ state.allow?(:oth) ]
          raise SyntaxError, msg unless conditions.all?
          state.allow_all except: [ :hsh, :spc ]
        end

        i += 1
      end
      msg_end = "The string '#{str}' ends with an illegal character."
      raise SyntaxError, msg_end unless state.allow?(:end)

      char = counterpart[count.find { |k,v| v != 0 }&.first]
      msg_bal = "The string '#{str}' is missing a #{char}."
      raise SyntaxError, msg_bal unless count.all? { |k,v| v == 0 }
    end

    class SyntaxState
      def initialize(*state_names)
        @status = Hash[state_names.map {|s| [s, :prohibited]}]
      end

      def allow(key)
        @status[key] = :allowed
      end

      def allow?(status)
        @status[status] == :allowed
      end

      def allow_all(except: [])
        set_all :allowed, except: { exceptions: except, status: :prohibited }
      end

      def prohibit(key)
        @status[key] = :prohibited
      end

      def prohibit?(status)
        @status[status] == :prohibited
      end

      def prohibit_all(except: [])
        set_all :prohibited, except: { exceptions: except, status: :allowed }
      end

      def set_all(status, except: {})
        @status.transform_values! { |v| v = status }
        except[:exceptions].each { |k| @status[k] = except[:status] }
      end
    end
  end

  class TypeElement
    attr_accessor :name
    attr_accessor :collection

    def initialize(name:, collection: nil)
      msg = 'Argument name was not a String.'
      raise TypeError, msg unless name.is_a? String
      msg = 'Argument name was an empty string.'
      raise ArgumentError, msg if name.empty?
      msg = 'Argument collection was not an Array.'
      raise TypeError, msg unless (collection.nil? || collection.is_a?(Array))
      msg = 'Argument collection was empty.'
      raise ArgumentError, msg if collection&.empty?

      @name = name
      @collection = collection
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
  end
end