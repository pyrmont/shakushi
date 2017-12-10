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
        c.match arg
      end
      msg = "The object '#{k}' is #{arg.class.name} but expected #{v}"
      raise TypeError, msg unless match
    end
  end

  module Parser
    def self.parse(str)
      check_syntax(str)

      content = ''
      stack = Array.new
      elements = Array.new
      stack.push elements

      str.each_char do |c|
        case c
        when '|'
          next if content.empty? # The previous character must have been '>'
          el = TypeCheck::ClassElement.new name: content
          content = ''
          elements = stack.pop
          elements.push el
          stack.push elements
        when '<'
          el = TypeCheck::ClassElement.new name: content
          content = ''
          stack.push el
          el_collection = Array.new
          stack.push el_collection
        when '>'
          if content.empty? # The previous character must have been '>'.
            parent_collection = stack.pop
          else
            el = TypeCheck::ClassElement.new name: content
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
        el = TypeCheck::ClassElement.new name: content
        elements = stack.pop
        elements.push el
        stack.push elements
      end

      stack.pop
    end

    def self.check_syntax(str)
      msg = "The argument to this method must be of type String."
      raise TypeError, msg unless str.is_a? String
      msg = "The string to be checked was empty."
      raise SyntaxError, msg if str.empty?

      counterpart = { lab: '>',
                      lpr: ')',
                      constraint: ': or #' }

      status = { bar: :unset,
                 lab: :unset,
                 rab: :unset,
                 lpr: :unset,
                 rpr: :unset,
                 hsh: :unset,
                 cln: :unset,
                 cma: :unset,
                 spc: :unset,
                 oth: :allowed,
                 end: :unset }
      count = { lab: 0, lpr: 0, hsh: 0, constraint: 0 }

      str.each_char.with_index do |c, i|
        msg = "The string '#{str}' has an error here: #{str[0, i+1]}"
        case c
        when '|' # bar
          conditions = [ status[:bar] == :allowed ]
          raise SyntaxError, msg unless conditions.all?
          status = set_all status, :prohibited, except: { oth: :allowed }
        when '<' # lab
          conditions = [ status[:lab] == :allowed ]
          raise SyntaxError, msg unless conditions.all?
          status = set_all status, :prohibited, except: { oth: :allowed }
          count[:lab] = count[:lab] + 1
        when '>' # rab
          conditions = [ status[:rab] == :allowed, count[:lab] > 0 ]
          raise SyntaxError, msg unless conditions.all?
          status = set_all status, :prohibited, except: { bar: :allowed,
                                                          rab: :allowed,
                                                          lpr: :allowed,
                                                          end: :allowed }
          count[:lab] = count[:lab] - 1
        when '(' # lpr
          conditions = [ status[:lpr] == :allowed || count[:hsh] == 1 ]
          raise SyntaxError, msg unless conditions.all?
          status = set_all status, :prohibited, except: { hsh: :allowed,
                                                          oth: :allowed }
          count[:lpr] = count[:lpr] + 1
          count[:constraint] = count[:constraint] + 1
        when ')' # rpr
          conditions = [ status[:rpr] == :allowed, count[:lpr] > 0 ]
          raise SyntaxError, msg unless conditions.all?
          status = set_all status, :prohibited, except: { bar: :allowed,
                                                          end: :allowed }
          count[:lpr] = count[:lpr] - 1
        when '#' # hsh
          conditions = [ status[:hsh] == :allowed ]
          raise SyntaxError, msg unless conditions.all?
          status = set_all status, :prohibited, except: { oth: :allowed }
          count[:constraint] = count[:constraint] - 1
          count[:hsh] = count[:hsh] + 1
        when ':' # cln
          conditions = [ status[:cln] == :allowed ]
          raise SyntaxError, msg unless conditions.all?
          status = set_all status, :prohibited, except: { spc: :allowed }
          count[:constraint] = count[:constraint] - 1
        when ',' # cma
          conditions = [ status[:cma] == :allowed ]
          raise SyntaxError, msg unless conditions.all?
          status = set_all status, :prohibited, except: { spc: :allowed }
          count[:constraint] = count[:constraint] + 1
        when ' ' # spc
          conditions = [ status[:spc] == :allowed ]
          raise SyntaxError, msg unless conditions.all?
          status = set_all status, :prohibited, except: { oth: :allowed }
        else # oth
          conditions = [ status[:oth] == :allowed ]
          raise SyntaxError, msg unless conditions.all?
          status = set_all status, :allowed, except: { spc: :prohibited }
        end
      end
      msg_end = "The string '#{str}' ends with an illegal character."
      raise SyntaxError, msg_end unless status[:end] == :allowed

      char = counterpart[count.find { |k,v| v != 0 }&.first]
      msg_bal = "The string '#{str}' is missing a #{char}."
      raise SyntaxError, msg_bal unless count.all? { |k,v| v == 0 }
    end

    def self.set_all(status, new_value, except: {})
      status.transform_values! { |v| v = new_value }
      except.each { |k,v| status[k] = v }
      status
    end
  end

  class ClassElement
    attr_accessor :name
    attr_accessor :collection

    def initialize(name:, collection: nil)
      msg = 'Argument name was not a String.'
      raise TypeError, msg unless name.is_a? String
      msg = 'Argument name was an empty string.'
      raise ArgumentError, msg if name.empty?
      msg = 'Argument collection was not an Array.'
      raise TypeError, msg unless (collection.nil? || collection.is_a?(Array))

      @name = name
      @collection = collection
    end

    def ==(comp)
      msg = 'Object to be compared must be of type TypeCheck::ClassElement.'
      raise TypeError, msg unless comp.is_a? TypeCheck::ClassElement

      @name == comp.name && @collection == comp.collection
    end

    def match(arg)
      if @name == 'Boolean'
        element_match = arg.is_a?(TrueClass) || arg.is_a?(FalseClass)
      else
        msg = "Class to match #{@name} is not defined"
        raise SyntaxError, msg unless Object.const_defined? @name
        element_match = arg.is_a? Object.const_get(@name)
      end

      child_match = if @collection.nil?
                      true
                    else
                      arg.is_a?(Enumerable) && arg.reduce(false) do |memo, a|
                        @collection.reduce(false) do |col_memo, c|
                          break true if col_memo == true
                          c.match a
                        end
                      end
                    end

      element_match && child_match
    end
  end
end