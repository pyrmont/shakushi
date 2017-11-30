module Shakushi
  module TypeCheck
    alias types binding

    def check(context, **checks)
      checks.each do |k, v|
        arg = context.local_variable_get(k)
        classes = TypeCheck::Parser.parse v
        match = classes.reduce(false) do |memo, c|
          break memo if memo == true
          memo = TypeCheck::ClassElement.match arg, c
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
            el = Shakushi::TypeCheck::ClassElement.new
            el.name = content
            content = ''
            elements = stack.pop
            elements.push el
            stack.push elements
          when '<'
            el = Shakushi::TypeCheck::ClassElement.new
            el.name = content
            content = ''
            stack.push el
            el_collection = Array.new
            stack.push el_collection
          when '>'
            if content.empty? # The previous character must have been '>'.
              parent_collection = stack.pop
            else
              el = Shakushi::TypeCheck::ClassElement.new
              el.name = content
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
          el = Shakushi::TypeCheck::ClassElement.new
          el.name = content
          elements = stack.pop
          elements.push el
          stack.push elements
        end

        stack.pop
      end

      def self.check_syntax(str)
        msg = "The string to be checked was empty."
        raise SyntaxError, msg if str.empty?

        status = { alt: :unset, col: :unset}
        count = { col: 0 }

        str.each_char.with_index do |c, i|
          msg = "The string '#{str}' has an error here: #{str[0, i+1]}"
          case c
          when '|'
            raise SyntaxError, msg unless status[:alt] == :allowed
            status[:alt] = :prohibited
            status[:col] = :prohibited
          when '<'
            raise SyntaxError, msg unless status[:col] == :allowed
            status[:alt] = :prohibited
            status[:col] = :opened
            count[:col] = count[:col] + 1
          when '>'
            sc = status[:col]
            raise SyntaxError, msg unless count[:col] > 0
            raise SyntaxError, msg unless sc == :allowed || sc == :closed
            status[:alt] = :allowed
            status[:col] = :closed
            count[:col] = count[:col] - 1
          else
            raise SyntaxError, msg if status[:col] == :closed
            status[:alt] = :allowed
            status[:col] = :allowed
          end
        end
        msg_ending = "The string '#{str}' ends with an illegal character."
        msg_balance = "The string '#{str}' is missing a closing '>'."
        sa = status[:alt]
        sc = status[:col]
        raise SyntaxError, msg_ending if sa == :prohibited || sc == :open
        raise SyntaxError, msg_balance if count[:col] > 0
      end
    end

    class ClassElement
      attr_accessor :name
      attr_accessor :collection

      def self.match(arg, class_element)
        col = class_element.collection
        name = class_element.name

        if name == 'Boolean'
          element_match = arg.is_a?(TrueClass) || arg.is_a?(FalseClass)
        else
          msg = "Class to match #{name} is not defined"
          raise SyntaxError, msg unless Object.const_defined? name
          element_match = arg.is_a? Object.const_get(class_element.name)
        end

        child_match = if col.nil?
                        true
                      else
                        arg.is_a?(Enumerable) && arg.reduce(false) do |memo, a|
                          col_match = col.reduce(false) do |memo, c|
                            break true if memo == true
                            memo = TypeCheck::ClassElement.match a, c
                          end
                        end
                      end

        element_match && child_match
      end
    end
  end
end