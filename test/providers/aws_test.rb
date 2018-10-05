require 'minitest/autorun'

require 'core/scenario'
require 'providers/aws'

require 'net/ssh'

# integration test of aws provider.
class AWSTest < Minitest::Test

  def test_all
    scenario_config = Scenario.load_from_yaml_file('./scenarios/test/basic/basic.yml')
    #scenario_config = Scenario.load_from_yaml_file('./scenarios/production/treasurehunt/treasurehunt.yml')
    scenario = EDURange::AWS.foo(scenario_config)
#    instance = scenario.clouds.first.subnets.first.instances.first


#    puts instance.administrators
#    user = instance.administrators.first

    scenario.start
#    puts "public ip: #{instance.public_ip_address}"

    sleep 60*2

    scenario.stop

#    begin
#      Net::SSH.start(instance.public_ip_address, user.login, password: user.password) do |ssh|
#        puts ssh.exec! 'ls /'
#      end
#    ensure
#      scenario.stop
#    end
  end

end

