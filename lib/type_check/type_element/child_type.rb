module TypeCheck
  class TypeElement
    class ChildType < Array
      def initialize(*child)
        child.each do |c|
          self.push c
        end
      end
    end
  end
end

