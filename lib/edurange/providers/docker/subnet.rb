require 'edurange/providers/logging/instance'
require 'edurange/providers/logging/subnet'

require 'semantic_logger'

class EDURange::Docker::Subnet
  include SemanticLogger::Loggable
  prepend EDURange::Logging::Subnet

  def initialize(subnet_config)
    @subnet_config = subnet_config
  end

  def self.find_existing_docker_network config
    filter = {
      name: [config.name]
    }
    Docker::Network.all(filters: [filter.to_json]).first
  end

  def self.create_docker_network config
    Docker::Network.create(config.name, docker_network_config(config) )
  end

  def self.docker_network_config config
    {
      IPAM: {
        Config: [{
          Subnet: config.cidr_block.to_string,
        }]
      }
    }
  end

  def find_existing_docker_network
    self.class.find_existing_docker_network(@subnet_config)
  end

  def create_docker_network
    self.class.create_docker_network(@subnet_config)
  end

  # TODO: these aren't "wrapped"
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

  def docker_network_started?
    !find_existing_docker_network.nil?
  end

  def all_instances_started?
    instances.all? { |i| i.started? }
  end

  def started?
    docker_network_started? and all_instances_started?
  end

  def start
    find_existing_docker_network || create_docker_network
    start_instances
  end

  def start_instances
    instances.each do |instance|
      instance.start
    end
  end

  def stop_instances
    instances.each do |instance|
      instance.stop
    end
  end

  def remove_network
    docker_network = find_existing_docker_network
    if docker_network then
      docker_network.remove
    end
  end

  def stop
    stop_instances
    remove_network
  end

end

