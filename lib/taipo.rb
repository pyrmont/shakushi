require_relative 'taipo/check'
require_relative 'taipo/parser'

module Taipo
  def self.instance_method?(str)
    str[0] == '#'
  end

  def self.child_types_string(arg)
    child_types = Hash.new
    arg.each { |a| child_types[a.class.name] = true }
    '<' + child_types.keys.join('|') + '>'
  end
end