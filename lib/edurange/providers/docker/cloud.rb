require 'edurange/providers/logging/subnet'

class EDURange::Docker::Cloud

  def initialize cloud_config
    @cloud_config = cloud_config
  end

  def subnets
    @subnets ||= @cloud_config.subnets.map do |subnet_config|
      EDURange::Docker::Subnet.new(subnet_config).extend(EDURange::Logging::Subnet)
    end
  end

  def instances
    subnets.flat_map{ |subnet| subnet.instances }
  end

  def start
    subnets.each do |subnet|
      subnet.start
    end
  end

  def stop
    subnets.each do |subnet|
      subnet.stop
    end
  end

end

