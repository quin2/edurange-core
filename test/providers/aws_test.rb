require 'minitest/autorun'

require 'core/scenario'
require 'providers/aws'
require 'logging'

require 'net/ssh'

# integration test of aws provider.
class AWSTest < Minitest::Test
  include SemanticLogger::Loggable

  def test_all
    scenario_config = Scenario.load_from_yaml_file('./scenarios/test/basic/basic.yml')
    #scenario_config = Scenario.load_from_yaml_file('./scenarios/production/treasurehunt/treasurehunt.yml')
    scenario = EDURange::AWS.foo(scenario_config)
    instance = scenario.clouds.first.subnets.first.instances.first
    user = instance.administrators.first

    scenario.start

    logger.info 'authenticate with', login: user.login, password: user.password.to_s

    begin
      Net::SSH.start(
        instance.public_ip_address,
        user.login,
        password: user.password.to_s,
        non_interactive: true
      ) do |ssh|
        puts "we connected via ssh"
        puts ssh.exec! 'ls /'
      end
    rescue
      logger.error 'error connecting to instance'
      raise
    ensure
      scenario.stop
    end
  end

end

