require 'minitest/autorun'

require 'core/scenario'

class ScenarioTest < Minitest::Test

  def setup
  end

  def test_treasurehunt_parses
    scenario = Scenario.load_from_yaml_file './scenarios/production/treasurehunt/treasurehunt.yml'
  end

end

