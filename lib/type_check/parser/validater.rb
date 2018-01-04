require_relative 'syntax_state'

module TypeCheck
  module Parser
    module Validater
      def self.validate(str)
        msg = "The argument to this method must be of type String."
        raise TypeError, msg unless str.is_a? String
        msg = "The string to be checked was empty."
        raise SyntaxError, msg if str.empty?

        status_array = [ :bar, :lab, :rab, :lpr, :rpr, :hsh, :cln, :sls, :qut,
                         :cma, :spc, :oth, :end ]
        counter_array = [ [ :angle, :paren, :const ],
                          { angle: '>', paren: ')', const: ":' or '#" } ]
        state = TypeCheck::Parser::SyntaxState.new(status_array, counter_array)

        i = 0
        chars = str.chars
        str_length = chars.size

        state.prohibit_all except: [ :hsh, :oth ]

        while (i < str_length)
          msg = "The string '#{str}' has an error here: #{str[0, i+1]}"
          case chars[i]
          when '|' # bar
            conditions = [ state.allowed?(:bar) ]
            raise SyntaxError, msg unless conditions.all?
            state.enable :lab
            state.enable :lpr
            state.prohibit_all except: [ :hsh, :oth ]
          when '<' # lab
            conditions = [ state.allowed?(:lab) ]
            raise SyntaxError, msg unless conditions.all?
            state.prohibit_all except: [ :hsh, :oth ]
            state.increment :angle
          when '>' # rab
            conditions = [ state.allowed?(:rab), state.inside?(:angle) ]
            raise SyntaxError, msg unless conditions.all?
            state.prohibit_all except: [ :bar, :rab, :lpr, :end ]
            state.decrement :angle
          when '(' # lpr
            conditions = [ state.allowed?(:lpr), state.outside?(:paren) ]
            raise SyntaxError, msg unless conditions.all?
            state.prohibit_all except: [ :hsh, :oth ]
            state.increment :paren
            state.increment :const
          when ')' # rpr
            conditions = [ state.allowed?(:rpr), state.inside?(:paren) ]
            raise SyntaxError, msg unless conditions.all?
            state.prohibit_all except: [ :bar, :rab, :end ]
            state.decrement :paren
          when '#' # hsh
            conditions = [ state.allowed?(:hsh) ]
            raise SyntaxError, msg unless conditions.all?
            if state.outside? :paren
              state.disable :lab
              state.disable :lpr
              state.prohibit_all except: [ :oth ]
            else
              state.prohibit_all except: [ :oth ]
              state.decrement :const
            end
          when ':' # cln
            conditions = [ state.allowed?(:cln), state.inside?(:paren) ]
            raise SyntaxError, msg unless conditions.all?
            state.prohibit_all except: [ :sls, :qut, :spc, :oth ]
            state.decrement :const
          when '/' #sls
            conditions = [ state.allowed?(:sls), state.inside?(:paren),
                           state.outside?(:const) ]
            raise SyntaxError, msg unless conditions.all?
            i = TypeCheck::Parser::Validater.validate_regex(str, start: i+1)
            state.prohibit_all except: [ :rpr, :cma ]
          when '"' #qut
            conditions = [ state.allowed?(:qut), state.inside?(:paren),
                           state.outside?(:const) ]
            raise SyntaxError, msg unless conditions.all?
            i = TypeCheck::Parser::Validater.validate_string(str, start: i+1)
            state.prohibit_all except: [ :rpr, :cma ]
          when ',' # cma
            conditions = [ state.allowed?(:cma),
                           state.inside?(:angle) || state.inside?(:paren) ]
            raise SyntaxError, msg unless conditions.all?
            state.prohibit_all except: [ :spc, :oth ]
            state.increment :const if state.inside?(:paren)
          when ' ' # spc
            conditions = [ state.allowed?(:spc) ]
            raise SyntaxError, msg unless conditions.all?
            state.prohibit_all except: [ :hsh, :sls, :qut, :oth ]
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
          if state.active?(:backslash) # The preceding character was a backslash.
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
            next if state.allowed?(:oth)
            finish = i
            break # The string has ended.
          else
            raise SyntaxError, msg unless state.allowed?(:oth)
            state.allow_all
          end
        end

        msg = "The string '#{str}' is missing a '/'."
        raise SyntaxError, msg if finish == start

        finish - 1
      end

      def self.validate_string(str, start: 0)
        status_array = [ :bsl, :qut, :oth ]
        counter_array = [ [ :backslash ], { backslash: '/' } ]

        state = SyntaxState.new(status_array, counter_array)
        state.prohibit_all except: [ :bsl, :oth ]
        finish = start

        str[start, str.length-start].each_char.with_index(start) do |c, i|
          if state.active?(:backslash) # The preceding character was a backslash.
            state.decrement :backslash
            next # Any character after a backslash is allowed.
          end

          msg = "The string '#{str}' has an error here: #{str[0, i+1]}"

          case c
          when '"'
            raise SyntaxError, msg unless state.allowed?(:qut)
            state.prohibit_all
          when '\\'
            raise SyntaxError, msg unless state.allowed?(:bsl)
            state.increment :backslash
          when ',', ')'
            next if state.allowed?(:oth)
            finish = i
            break # The string has ended.
          else
            raise SyntaxError, msg unless state.allowed?(:oth)
            state.allow_all
          end
        end

        msg = "The string '#{str}' is missing a '\"'."
        raise SyntaxError, msg if finish == start

        finish - 1
      end
    end
  end
end
