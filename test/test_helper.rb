require 'minitest/autorun'
require 'minitest/reporters'
require 'shoulda/context'

# Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
# Minitest::Reporters.use!
Minitest::Reporters.use! [
  Minitest::Reporters::DefaultReporter.new(:color => false)]

module ShakushiTestHelper
end
