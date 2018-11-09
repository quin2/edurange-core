
require_relative '../test_helper'

require 'core/scenario'
require 'pathname'
require 'yaml'

class ScenarioTest < Minitest::Test

  attr_reader :directory, :hash

  BASIC_FILENAME = './scenarios/test/basic/basic.yml'

  def setup
    path = Pathname.new BASIC_FILENAME
    @directory = path.dirname
    @hash = YAML.load path.read
  end

  def test_basic_valid
    Scenario.load_from_yaml_file BASIC_FILENAME
  end

  def test_scenario_name_required
    hash.delete(Scenario::NAME_KEY)
    assert_raises ArgumentError do
      Scenario.new directory, hash
    end
  end

  def test_scenario_name_not_nil
    hash[Scenario::NAME_KEY] = nil
    assert_raises ArgumentError do
      Scenario.new directory, hash
    end
  end

  def test_scenario_name_valid_characters
    hash[Scenario::NAME_KEY] = '%wat!'
    assert_raises ArgumentError do
      Scenario.new directory, hash
    end
  end

  def test_directory_must_exist
    bad_directory = Pathname.new '/this/directory/probably/does/not/exists'
    assert_raises ArgumentError do
      Scenario.new bad_directory, hash
    end
  end

  def test_cloud_ip_valid
    hash[Scenario::CLOUDS_KEY].each do |cloud_hash|
      cloud_hash[Cloud::CIDR_BLOCK_KEY] = '666.666.666.666'
   end
   assert_raises ArgumentError do
     Scenario.new directory, hash
   end
  end

  def test_subnet_cidr_block_valid
    hash[Scenario::CLOUDS_KEY].first[Cloud::SUBNETS_KEY].first[Subnet::CIDR_BLOCK_KEY] = '0.0.0.0'
    assert_raises ArgumentError do
      Scenario.new directory, hash
    end

    hash[Scenario::CLOUDS_KEY].first[Cloud::SUBNETS_KEY].first[Subnet::CIDR_BLOCK_KEY] = '2001:db8::ff00:42:8329/24'
    assert_raises ArgumentError do
      Scenario.new directory, hash
    end

    hash[Scenario::CLOUDS_KEY].first[Cloud::SUBNETS_KEY].first[Subnet::CIDR_BLOCK_KEY] = '10.0.1.0/24'
    assert_raises ArgumentError do
      Scenario.new directory, hash
    end
  end

  def test_bad_instance_access_reference
    hash[Scenario::GROUPS_KEY].first[Group::ACCESS_KEY].first[Access::INSTANCE_KEY] = 'ObviouslyNotTheRightName'
    assert_raises ArgumentError do
      Scenario.new directory, hash
    end
  end

  def test_players
    scenario = Scenario.new(directory, hash)
    player = scenario.players.first
    assert_equal('james', player.login)
    assert_equal('s00p3rs3cr37', player.password.to_s)
  end

  def test_player_variable_set
    scenario = Scenario.new(directory, hash)
    player = scenario.players.first
    assert(!player.variables.flag.nil?)
  end

end

