require 'ipaddress'
require 'active_support/core_ext/object'
require_relative 'subnet'


class Cloud
  attr_reader :scenario, :name, :cidr_block, :subnets
  attr_writer :scenario, :name

  NAME_KEY = 'Name'
  CIDR_BLOCK_KEY = 'CIDR_Block'
  SUBNETS_KEY = 'Subnets'

  def initialize scenario, hash
    self.scenario = scenario
    self.name = hash[NAME_KEY]
    self.cidr_block = hash[CIDR_BLOCK_KEY]
    subnet_hash_list = hash[SUBNETS_KEY] || []
    self.subnets = subnet_hash_list.map{ |subnet_hash| Subnet.new self, subnet_hash }
  end

  def to_hash
    {
      NAME_KEY => name,
      CIDR_BLOCK_KEY => cidr_block.to_string,
      SUBNETS_KEY => subnets.map{|subnet| subnet.to_hash}
    }
  end

  def instances
    subnets.flat_map{ |subnet| subnet.instances }
  end

  def cidr_block= cidr_block
    ip = IPAddress.parse cidr_block
    raise "Cloud #{CIDR_BLOCK_KEY} subnet mask #{ip.prefix} is not between 16 and 28" unless ip.prefix >= 16 and ip.prefix <= 28
    raise "Cloud #{CIDR_BLOCK_KEY} #{ip.to_string} is not IPv4" unless ip.ipv4?
    @cidr_block = ip
    #ip, mask = cidr_block.split('/')
    #raise "Cloud '#{CIDR_BLOCK_KEY}' IP '#{ip}' is invalid" unless IPAddress.valid_ipv4(ip)
    #raise "Cloud '#{CIDR_BLOCK_KEY}' needs a subnet mask" if mask.blank?
  end

  def subnets= subnets
    raise "Cloud #{SUBNETS} must not be empty" if subnets.blank?
    @subnets = subnets
  end

end

