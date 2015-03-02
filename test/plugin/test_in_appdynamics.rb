require 'helper'

class appdynamicsTrapInputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end
  
  # Add config here
  CONFIG = %[
    # Example hostt 0
    # Example port 1062
    # Example tag alert.snmptrap
  ]

  def create_driver(conf=CONFIG)
    Fluent::Test::InputTestDriver.new(Fluent::appdynamicsTrapInput).configure(conf)
  end

  # Configure the test
  def test_configure
    d = create_driver('')
    # Example assert_equal "0".to_i, d.instance.host
    # Example assert_equal "1062".to_i, d.instance.port
    # Example assert_equal 'alert.snmptrap', d.instance.tag
  end
end
