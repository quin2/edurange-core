require 'edurange/providers/logging/instance'
require 'edurange/providers/logging/subnet'

require 'semantic_logger'

class EDURange::Docker::Subnet
  include SemanticLogger::Loggable
  prepend EDURange::Logging::Subnet

  def initialize(subnet_config)
    @subnet_config = subnet_config
    filter = {
      name: [@subnet_config.name]
    }
    @docker_network = Docker::Network.all(filters: [filter.to_json]).first
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
    @docker_network = Docker::Network.create(name, docker_network_config)

    instances.each do |instance|
      instance.start
    end
  end

  def stop
    instances.each do |instance|
      instance.stop
    end
    if @docker_network then
      @docker_network.remove
    end
  end

  def docker_network_config
    {
      IPAM: {
        Config: [{
          Subnet: @subnet_config.cidr_block.to_string,
        }]
      }
    }
  end

end

