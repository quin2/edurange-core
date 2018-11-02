require 'pathname'
require 'semantic_logger'

class EDURange::Docker::Instance
  include SemanticLogger::Loggable
  extend Forwardable

  def initialize(subnet, instance_config)
    @subnet = subnet
    @instance_config = instance_config
  end

  delegate [:name, :os, :ip_address, :ip_address_dynamic, :users, :administrators, :recipes, :packages, :internet_accessible?, :roles] => :@instance_config


  # TODO, the following three definitions are identical to core/instance definition.
  # this class should extend that class
  def subnet
    @subnet
  end

  def scenario
    subnet.scenario
  end

  def cloud
    subnet.cloud
  end

  def public_ip_address
    IPAddress.parse '127.0.0.1' # TODO: just a hack to get started. Running docker on localhost.
  end

  # kind of a hack, is ssh_port provider specific?
  def ssh_host_port
    if @container
      @container.json['NetworkSettings']['Ports']['22/tcp'].first['HostPort'].to_i
    end
  end

  # TODO: refactor image and container stuff into separate class. instance can coordinate between them.
  def docker_image_repository
    name.downcase
  end

  def docker_image_tag
    'latest'
  end

  def start
    #image = Docker::Image.create('fromImage' => 'ubuntu:14.04')
    image = Docker::Image.build_from_dir(directory.to_s)
    image.tag(repo: docker_image_repository, tag: docker_image_tag)
    image.push

    @container = Docker::Container.create(
      Image: image.id,
      ExposedPorts: {'22/tcp' => {}},
      Hostname: name,
      name: name, # TODO unique name
      HostConfig: docker_container_host_config,
      NetworkingConfig: docker_container_network_config
    )

    @container.start
  end

  def docker_container_network_config
    {
      EndpointsConfig: {
        "#{@subnet.docker_network_name}" => {
          IPAMConfig: {
            IPv4Address: @instance_config.ip_address.address
          }
        }
      }
    }
  end

  def docker_container_host_config
    if internet_accessible? then
      return {
        PortBindings: {
          '22/tcp' => [{ HostPort: '0'}] # 0 will assign a free port
        }
      }
    end
  end

  private :docker_container_network_config
  private :docker_container_host_config

  def stop
    @container.stop
    @container.remove
  end

  def directory
    Pathname.new(__FILE__).dirname
  end

  private :directory

end

