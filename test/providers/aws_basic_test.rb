require_relative 'basic_scenario_test_base'
require 'providers/aws'

class AWSBasicScenarioTest < Minitest::Test
  include BasicScenarioTestBase

  def provider
    EDURange::AWS
  end

end

