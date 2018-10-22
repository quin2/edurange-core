require 'ipaddress'
require 'active_support/core_ext/object/blank'

require_relative 'instance'
require_relative 'legacy_instance'
require_relative 'inspect'

class Subnet
  include Inspect

  attr_reader :cloud, :name, :cidr_block, :instances, :internet_accessible

  NAME_KEY = 'Name'
  CIDR_BLOCK_KEY = 'CIDR_Block'
  INTERNET_ACCESSIBLE_KEY = 'Internet_Accessible'
  INSTANCES_KEY = 'Instances'

  def initialize cloud, hash
    self.name = hash[NAME_KEY]
    self.cloud = cloud
    self.internet_accessible = hash[INTERNET_ACCESSIBLE_KEY] || false
    self.cidr_block = hash[CIDR_BLOCK_KEY]
    instance_hashes = hash[INSTANCES_KEY] || []
    self.instances = instance_hashes.map{ |instance_hash| LegacyInstance.new (Instance.new self, instance_hash) }
  end

  def to_hash
    {
      NAME_KEY => name,
      CIDR_BLOCK_KEY => cidr_block.to_string,
      INTERNET_ACCESSIBLE_KEY => internet_accessible?,
      INSTANCES_KEY => instances.map{ |instance| instance.to_hash }
    }
  end

  def scenario
    cloud.scenario
  end

  alias internet_accessible? internet_accessible

  private

  attr_writer :cloud, :internet_accessible

  def cidr_block= cidr_block
    ip = IPAddress.parse cidr_block
    raise ArgumentError, "Subnet #{CIDR_BLOCK_KEY} #{ip.to_string} must be IPv4" unless ip.ipv4?
    raise ArgumentError, "Subnet #{CIDR_BLOCK_KEY} #{ip.to_string} is not a valid network" unless ip.network?
    raise ArgumentError, "Subnet #{CIDR_BLOCK_KEY} #{ip.to_string} is not contained in Cloud #{CIDR_BLOCK_KEY} #{cloud.cidr_block.to_string}" unless cloud.cidr_block.include? ip
    @cidr_block = ip
  end

  def name= name
    raise "Subnet #{NAME_KEY} '#{name}' must only contain alphanumeric characters and underscores" if /\W/.match name
    @name = name
  end

  def instances= instances
    raise "#{self.class.name} #{INSTANCES_KEY} must not be empty" if instances.blank?
    duplicates = instances \
      .group_by{ |instance| instance.ip_address.to_s } \
      .select{ |ip, is| is.size > 1 }
      .map{ |ip, is| ip }
    raise "Subnet contains Instances with duplicate ip_address(es): #{duplicates.join(',')}" if duplicates.count > 0
    @instances = instances
  end

end

