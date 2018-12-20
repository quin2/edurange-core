

module EDURange::Docker::InstanceContainer

  def self.create(image, instance)
    container_config = config(image, instance)
    Docker::Container.create(container_config)
  end

  def self.find(instance)
    filter = {
      label: [
        "edu.range.instance=#{instance.name}",
        "edu.range.scenario=#{instance.scenario.name}"
      ]
    }
    Docker::Container.all(all: true, filters: [filter.to_json]).first
  end

  def self.config(image, instance)
    {
      Image: image.id,
      ExposedPorts: {'22/tcp' => {}},
      Hostname: instance.name,
      name: instance.name, # TODO unique name
      HostConfig: host_config(instance),
      NetworkingConfig: network_config(instance)
    }
  end

  def self.network_config(instance)
    {
      EndpointsConfig: {
        "#{instance.subnet.name}" => {
          IPAMConfig: {
            IPv4Address: instance.ip_address.address
          }
        }
      }
    }
  end

  def self.host_config(instance)
    config = {
      CapAdd: [
        "NET_ADMIN" # this is needed for scenarios that use iptables to modify network config
      ]
    }

    if instance.internet_accessible? then
      config = config.merge({
        PortBindings: {
          '22/tcp' => [{ HostPort: '0'}] # 0 will assign a free port
        }
      })
    end
    config
  end

end

