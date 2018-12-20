require_relative '../test_helper.rb'

require 'edurange/core/scenario'
require 'logging'

require 'net/ssh'

# Integration test of a generic provider.
# Implement a 'provider' and 'scenario_config' method in classes that include this module
module BasicScenarioTestBase
  #include SemanticLogger::Loggable

  def scenario_config
    @scenario_config ||= Scenario.load_from_yaml_file('./scenarios/test/basic/basic.yml')
  end

  def test_all
    scenario = provider.foo(scenario_config)
    assert_respond_to(scenario, :start)
    assert_respond_to(scenario, :stop)

    instance = scenario.clouds.first.subnets.first.instances.first
    assert_respond_to(instance, :public_ip_address)

    user = instance.users.first
    assert_respond_to(user, :login)
    assert_respond_to(user, :password)

    scenario.start

    # TODO, providers shouldn't return from start unless they are ready for connections.
    gets

    # logger.info 'authenticate with', login: user.login, password: user.password.to_s
    begin
      Net::SSH.start(
        instance.public_ip_address.to_s,
        user.login,
        port: instance.host_ssh_port,
        password: user.password.to_s,
        non_interactive: true
      ) do |ssh|
        # logger.info 'we connected via ssh'
        message = ssh.exec! "cat /home/#{user.login}/flag"
        assert_equal(user.variables.flag, message.strip)
        # logger.info message.strip
      end
#    rescue => e
#      flunk(exception_details(e, 'Log on to instance with ssh'))
    ensure
      scenario.stop
    end
  end

  def test_extends_scenario
    skip
    Scenario.instance_methods.each do |method|
      assert(provider::Scenario.instance_methods.include?(method), "Provider Scenario does not implement method '#{method}'")
    end
  end

  def test_reattach_scenario
    skip
    # a scenario that has been started should be able to be reattched to

    initial_scenario = provider.foo(scenario_config)
    initial_scenario.start

    reattached_scenario = provider.foo(scenario_config)
    assert(reattached_scenario.started?)
    #assert_equals(initial_scenario, reattached_scenario)

    reattached_scenario.stop

    assert(!reattached_scenarion.started?)
  end

end

