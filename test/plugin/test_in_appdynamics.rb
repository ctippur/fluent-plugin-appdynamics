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
    tag alert.appdynamics.raw
  ]

  def create_driver(conf=CONFIG)
    Fluent::Test::InputTestDriver.new(Fluent::appdynamicsTrapInput, tag='test_tag').configure(conf)
  end

  # Configure the test
  def test_configure
    d = create_driver('')
    assert_equal "pleasechangeme.com", d.instance.endpoint
    assert_equal "username", d.instance.user
    assert_equal "password", d.instance.pass
    assert_equal "account", d.instance.account
    assert_equal "300".to_i, d.instance.interval
    assert_equal "false", d.instance.include_raw
    assert_equal 'alert.appdynamics.raw', d.instance.tag
    # Example assert_equal "0".to_i, d.instance.host
    # Example assert_equal "1062".to_i, d.instance.port
    # Example assert_equal 'alert.snmptrap', d.instance.tag
  end
end
