require_relative 'parser/syntax_state'

module TypeCheck
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
  end
end