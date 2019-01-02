require_relative '../test_helper'

require 'edurange/core/variable'

class VariableTest < Minitest::Test

  def test_name_validated
    assert_raises ArgumentError do
      Variable.from_hash({
        Variable::TYPE_KEY => 'string',
        Variable::VALUE_KEY => 'hello, world'
      })
    end

    assert_raises ArgumentError do
      Variable.from_hash({
        Variable::NAME_KEY => '%#@#$%!11111',
        Variable::TYPE_KEY => 'string',
        Variable::VALUE_KEY => 'hello, world'
      })
    end
  end

  def test_type_validated
    assert_raises ArgumentError do
      Variable.from_hash({
        Variable::NAME_KEY => 'Hi',
      })
    end

    assert_raises ArgumentError do
      Variable.from_hash({
        Variable::NAME_KEY => 'Hi',
        Variable::TYPE_KEY => 'i_am_fake'
      })
    end
  end

  def test_string
    expected_value = 'fadsga94gafd90jg9034'

    variable = Variable.from_hash({
      Variable::NAME_KEY => 'my_variable',
      Variable::TYPE_KEY => 'string',
      Variable::VALUE_KEY => expected_value
    })

    assert_equal(expected_value, variable.value)
  end

  def test_random
    variable = Variable.from_hash({
      Variable::NAME_KEY => 'my_variable',
      Variable::TYPE_KEY => 'random'
    })

    assert(variable.value.nil?)
    assert(!variable.generate_value.nil?)
    assert_equal(8, variable.generate_value.length)
  end

  def test_openssl_pkey_rsa
    variable = Variable.from_hash({
      Variable::NAME_KEY => 'my_variable',
      Variable::TYPE_KEY => 'openssl_pkey_rsa'
    })

    assert(variable.value.nil?)
    assert(!variable.generate_value.nil?)
    assert(variable.generate_value.start_with? '-----BEGIN RSA PRIVATE KEY-----')
  end

end

