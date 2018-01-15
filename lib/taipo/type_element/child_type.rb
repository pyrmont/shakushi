module Taipo
  class TypeElement
    class ChildType < Array
      def initialize(components = nil)
        components.each { |c| self.push c } unless components.nil?
      end
    end
  end
end

