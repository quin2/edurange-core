require 'forwardable'
require 'date'
require_relative 'subnet'

module EDURange
  module AWS
    class Cloud
      include SemanticLogger::Loggable
      extend Forwardable

      def initialize(ec2, s3, cloud_config, vpc = nil)
        @config = cloud_config
        @s3 = s3
        @ec2 = ec2
        @vpc = vpc
      end

#      def Cloud.create(cloud_config)
#        ec2 = Aws::EC2::Resource.new
#        Cloud.new(ec2, cloud_config)
#      end

#      def Cloud.find(cloud_config, vpc_id)
#        ec2 = Aws::EC2::Resource.new
#        vpc = ec2.vpc(vpc_id)
#        Cloud.new(ec2, cloud_config, vpc)
#      end

      delegate [:name, :cidr_block, :scenario] => :@config

      def subnets
        @subnets ||= @config.subnets.map{|subnet| EDURange::AWS::Subnet.new(subnet)}
      end

      def started?
        not @vpc.nil?
      end

      def start
        logger.trace "starting cloud", name: @config.name, scenario: @config.scenario.name
        raise "Cloud #{name} already started" if started?

        @vpc = @ec2.create_vpc({ cidr_block: cidr_block.to_string })

        Cloud.tag_cloud(@config, @vpc)

        # temporary
#        key_pair = @ec2.create_key_pair({
#          key_name: 'DUMMY'
#        })
#        Pathname.new("./#{key_pair.name}.pem").write(key_pair.key_material)

        gateway = Cloud.create_internet_gateway(@ec2, @vpc)

        Cloud.configure_default_security_group(@vpc)

        subnets.each do |subnet|
          subnet.start(@ec2, @s3, @vpc, gateway)
        end

        logger.trace "started cloud", name: @config.name, scenario: @config.scenario.name
      end

      def stop
        subnets.each{ |subnet| subnet.stop }
        Cloud.delete_internet_gateway(@vpc)
        @vpc.delete
      end

      def Cloud.tag_cloud(config, vpc)
        vpc.create_tags({
          tags: [
            {key: 'Name', value: config.name},
            {key: 'ScenarioName', value: config.scenario.name},
            {key: 'DateCreated', value: DateTime.now.iso8601}
          ]
        })
      end

      def Cloud.create_internet_gateway(ec2, vpc)
        gateway = ec2.create_internet_gateway()
        gateway.attach_to_vpc({
          vpc_id: vpc.id
        })
        gateway
      end

      def Cloud.delete_internet_gateway(vpc)
        vpc.internet_gateways().each do |internet_gateway|
          vpc.detach_internet_gateway({
            internet_gateway_id: internet_gateway.id
          })
          internet_gateway.delete
        end
      end

      def Cloud.configure_default_security_group(vpc)
        security_group = vpc.security_groups.first
        security_group.authorize_ingress({
          ip_permissions: [{
            ip_protocol: "tcp",
            from_port: 22,
            to_port: 22,
            ip_ranges: [
              {
                cidr_ip: "0.0.0.0/0",
              }
            ]
          }]
        })
      end

    end
  end
end


