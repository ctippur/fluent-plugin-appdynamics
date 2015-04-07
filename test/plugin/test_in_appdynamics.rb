require 'helper'

class AppdynamicsInputTest < Test::Unit::TestCase

  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    username test_username
    password test_password
    endpoint test.endpoint.com
  ]

  def create_driver(conf = CONFIG)
    Fluent::Test::InputTestDriver.new(Fluent::AppdynamicsInput).configure(conf)
  end

  def test_configure
    assert_nothing_raised { create_driver }
  end

  def test_params
    d = create_driver
    assert_equal "test.endpoint.com", d.instance.endpoint
    assert_equal "test_username", d.instance.username
    assert_equal "test_password", d.instance.password
    assert_equal "10".to_i, d.instance.interval
    assert_equal "false", d.instance.include_raw
    assert_equal 'alert.appdynamics', d.instance.tag
  end

end
