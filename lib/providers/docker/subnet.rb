require 'providers/logging/instance'
require 'semantic_logger'

class EDURange::Docker::Subnet
  include SemanticLogger::Loggable

  def initialize(subnet_config)
    @subnet_config = subnet_config
  end

  # TODO:
  def scenario
    @subnet_config.scenario
  end

  # TODO
  def cloud
    @subnet_config.cloud
  end

  def name
    @subnet_config.name
  end

  def instances
    @instances ||= @subnet_config.instances.map do |instance_config|
      EDURange::Docker::Instance.new(self, instance_config).extend(EDURange::Logging::Instance)
    end
  end

  def start
    @docker_network = Docker::Network.create(docker_network_name, docker_network_parameters)

    instances.each do |instance|
      instance.start
    end
  end

  def stop
    instances.each do |instance|
      instance.stop
    end
    @docker_network.remove
  end

  def docker_network_name
    return @subnet_config.name
  end

  def docker_network_parameters
    {
      IPAM: {
        Config: [{
          Subnet: @subnet_config.cidr_block.to_string,
        }]
      }
    }
  end

  #private :docker_network_name

end

